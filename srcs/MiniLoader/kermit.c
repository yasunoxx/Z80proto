// kermit.c -- Kermit C implement

// original copyright:
/*
001 ' KERMIT.BAS - Receive-only Kermit Protocol implementation for
002 ' bootstrapping a real Kermit program onto the PC.  Requires MS BASIC.
003 ' Start Basic, type in this program (you can leave out the comments),
004 ' SAVE, and then RUN.  Have the Kermit program on the other end of the 
005 ' COM port connection send the desired file at a speed of 1200bps
006 ' with no flow control.

010 ' Author: Frank da Cruz, October 1986.
*/

/*
100  RESET : RESET : RESET
110  ON ERROR GOTO 9000
120  DEFINT A-Z
*/

#define NUL 0
#define SOH 1
#define SPC 32
#define CR  13
#define LF  11
#define DEL 127

#define print_console
#define uint8_t unsigned char

uint8_t N, L, CHK, SEQ, EOL, CTL, TYP;
uint8_t SNDBUF[ 128 ], RCVBUF[ 128 ], PKTDAT[ 100 ];

void kermit_init( void );
uint8_t kermit_sendinit( void );
uint8_t kermit_gethdrpkt( void );
uint8_t kermit_getdatapkt( void );
char kermit_getpkt( void );
void kermit_putpkt( uint8_t );
uint8_t kermit_readpkt( void );
uint8_t kermit_len( uint8_t * );
void kermit_sendack( uint8_t * );
uint8_t kermit_senderr( uint8_t * );

uint8_t kermit_main()
{
    kermit_init();
    if( 0 != kermit_sendinit() ) return 0x0FF;
    kermit_getpkt();
//    while( 1 )
    {
        if( 0 != kermit_gethdrpkt() ) return 0x0FF;
        if( 0 != kermit_getdatapkt() ) return 0x0FF;
    }
    return 0;
}

void kermit_init()
{
    uint8_t loop;
// 1010 N = 0 : SNDBUF$ = CHR$(1)+"# N3"+CHR$(13)
    N = 0;
    for( loop = 0; loop < 6; loop++ )
    {
        const uint8_t str[] = " # N3 ";
        SNDBUF[ loop ] = str[ loop ];
    }
    SNDBUF[ 0 ] = SOH;
    SNDBUF[ 5 ] = CR;
    SNDBUF[ 6 ] = NUL;
// 1020 OPEN "COM1:1200,N,8,,CS,DS" AS #1
}

uint8_t kermit_sendinit()
{
    char stat;
// 2000 ' Get Send Initialization packet, exchange parameters.
// 2010 PRINT "Waiting..."
    print_console( "Waiting...\n" );
// 2020 GOSUB 5000
    stat = kermit_getpkt();
// 2030 IF TYP$ <> "S" THEN D$ = TYP$+" Packet in S State" : GOTO 9500
    if( stat != 'S' )
    {
        uint8_t str[] = "  Packet in S State";
        str[ 0 ] = ( uint8_t )stat;
        kermit_senderr( stat );
        return 0x0FF;
    }
// 2040 IF LEN(PKTDAT$) > 4 THEN EOL=ASC(MID$(PKTDAT$,5,1))-32 ELSE EOL=13
    if( 4 < kermit_len( PKTDAT ) )
    {
        EOL = PKTDAT[ 4 ];
    }
    else
    {
        EOL = 13;
    }
// 2050 IF LEN(PKTDAT$) > 5 THEN CTL=ASC(MID$(PKTDAT$,6,1)) ELSE CTL=ASC("#")
    if( 5 < kermit_len( PKTDAT ) )
    {
        CTL = PKTDAT[ 5 ];
    }
    else
    {
        CTL = '#';
    }
// 2070 D$ = "H* @-#N1" : GOSUB 8020
    kermit_sendack( ( uint8_t )"H* @-#N1" );
    return 0;
} // next: kermit_gethdrpkt()

uint8_t kermit_gethdrpkt()
{
    char stat;
// 3000 ' Get a File Header packet.  If a B packet comes, we're all done.
// 3010 GOSUB 5000
    stat = kermit_getpkt();
// 3020 IF TYP$ = "B" THEN GOSUB 8000 : GOTO 9900
    if( stat == 'B' )
    {
        kermit_sendack( ( uint8_t )"" );
        return 0x0FF;
    }
// 3030 IF TYP$ <> "F" THEN D$ = TYP$+" Packet in F State" : GOTO 9500
    if( stat != 'S' )
    {
        uint8_t str[] = "  Packet in S State";
        str[ 0 ] = ( uint8_t )stat;
        kermit_senderr( stat );
        return 0x0FF;
    }
// 3040 PRINT "Receiving "; MID$(PKTDAT$,1,L);
    print_console( "Receiving\n" );
// 3050 OPEN MID$(PKTDAT$,1,L) FOR OUTPUT AS #2
    // ... write file ...
// 3060 GOSUB 8000
    kermit_sendack( ( uint8_t )"" );
// next: kermit_getdatapkt()
    return 0;
}

uint8_t kermit_getdatapkt()
{
    char stat;
// 4000 ' Get Data packets.  If a Z packet comes, the file is complete.
    while( 1 )
    {
// 4010 GOSUB 5000
        stat = kermit_getpkt();
// 4020 IF TYP$ = "Z" THEN CLOSE #2 : GOSUB 8000 : PRINT "(OK)" : GOTO 3000
        if( stat == 'Z' )
        {
            kermit_sendack( ( uint8_t )"" );
            print_console( "(OK)\n" );
            break; // next: kermit_gethdrpkt()
        }

// 4030 IF TYP$ <> "D" THEN D$ = TYP$+" Packet in D State" : GOTO 9500
        if( stat != 'D' )
        {
            uint8_t str[] = "  Packet in D State";
            str[ 0 ] = ( uint8_t )stat;
            kermit_senderr( str );
            return 0x0FF;
        }

// 4040 PRINT #2, MID$(PKTDAT$,1,P);
    // ... write file ...
// 4060 GOSUB 8000
        kermit_sendack( ( uint8_t )"" );
// 4070 GOTO 4000
    }
    return 0;
}

char kermit_getpkt()
{
    uint8_t loop;
// 5000 ' Try to get a valid packet with the desired sequence number.
// 5010 GOSUB 7000
// 5020 FOR TRY = 1 TO 5
    for( loop = 0; loop < 5; loop++ )
    {
// 5030   IF SEQ = N AND TYP$ <> "Q" THEN RETURN
        if( 'Q' != kermit_readpkt() && SEQ == N )
        {
            return 'Q';
        }
// 5040   PRINT #1, SNDBUF$;
        // ... send data ...
// 5050   PRINT "%";
        print_console( "%" );
// 5060   GOSUB 7000
// 5070 NEXT TRY
    }
// 5080 TYP$ = "T" : RETURN
    return 'T';
}

void kermit_putpkt( uint8_t D )
{
    uint8_t loop, CHKSUM;
// 6000 ' Send a packet with data D$ of length L, type TYP$, sequence #N.
// 6010 SNDBUF$ = CHR$(1)+CHR$(L+35)+CHR$(N+32)+TYP$+D$+" "+CHR$(EOL)
    SNDBUF[ 0 ] = SOH;
    SNDBUF[ 1 ] = L + 35;
    SNDBUF[ 2 ] = N + 32;
    SNDBUF[ 3 ] = TYP;
    SNDBUF[ 4 ] = D;
    SNDBUF[ 5 ] = " ";
    SNDBUF[ 6 ] = EOL;
// 6020 CHKSUM = 0
    CHKSUM = 0;
// 6030 FOR I = 2 TO L+4
    for( loop = 2; loop < L + 4; loop++ )
    {
// 6040   CHKSUM = CHKSUM + ASC(MID$(SNDBUF$,I,1))
        CHKSUM += SNDBUF[ loop ];
// 6050 NEXT I
    }
// 6060 CHKSUM = (CHKSUM + ((CHKSUM AND 192) \ 64)) AND 63
    CHKSUM = ( CHKSUM + (( CHKSUM & 192 ) / 64 ) & 63 );
// 6070 MID$(SNDBUF$,L+5) = CHR$(CHKSUM + 32)
    SNDBUF[ ++loop ] = CHKSUM + 32;
    SNDBUF[ ++loop ] = NUL;
// 6080 PRINT #1, SNDBUF$;
    // ... send data ...
// 6100 RETURN
}

uint8_t kermit_instr( uint8_t *search, uint8_t target )
{
    uint8_t count = 0;

    while( 1 )
    {
        if( search[ count ] == CR || search[ count ] == LF )
        {
            return 0;
        }
        if( search[ count ] == target )
        {
            return target;
        }
        count++;
    }
}

uint8_t kermit_readpkt()
{
    uint8_t SOHpos, T, P, FLAG, loop;
// 7000 ' Routine to Read and Decode a Packet.
// 7010 LINE INPUT #1, RCVBUF$
// 7020 I = INSTR(RCVBUF$,CHR$(1))
// 7030 IF I = 0 THEN TYP$ = "Q" : RETURN
    SOHpos = kermit_instr( RCVBUF, SOH );
    if( 0 == SOHpos )
    {
        return 'Q';
    }

// 7100 CHK   = ASC(MID$(RCVBUF$,I+1,1)) : L   = CHK - 35
    CHK = RCVBUF[ SOHpos + 1 ];
    L = CHK - 35;
// 7110 T     = ASC(MID$(RCVBUF$,I+2,1)) : SEQ = T - 32 : CHK = CHK + T
    T = RCVBUF[ SOHpos + 2 ];
    SEQ = T - 32;
    CHK += T;
// 7120 TYP$  =     MID$(RCVBUF$,I+3,1)  : CHK = CHK + ASC(TYP$)
    TYP = RCVBUF[ SOHpos + 3 ];
    CHK += TYP;

// 7130 P = 0 : FLAG = 0 : PKTDAT$ = STRING$(100,32)
    P = 0;
    FLAG = 0;
    for( loop = 0; loop < 100; loop++)
    {
        PKTDAT[ loop ] = SPC;
    }
// 7200 FOR J = I+4 TO I+3+L
    for( loop = ( SOHpos + 4 ); loop < ( SOHpos + 3 + L ); loop++ )
    {
// 7210   T = ASC(MID$(RCVBUF$,J,1))
        T = RCVBUF[ loop ];
// 7220   CHK = CHK + T
        CHK = CHK + T;
// 7240   IF TYP$ = "S" THEN 7300
        if( TYP != 'S' )
        {
// 7250     IF FLAG = 0 AND T = CTL THEN FLAG = 1 : GOTO 7400
            if( FLAG == 0 && T == CTL )
            {
                FLAG = 1;
                goto L7400;
            }
        }

        {
// 7260     T7 = T AND 127
            uint8_t T7 = T & 127;
// 7270     IF FLAG THEN FLAG = 0 : IF T7 > 62 AND T7 < 96 THEN T = T XOR 64
            FLAG = 0;
            if( T7 > 62 && T7 < 96 )
            {
                T = T ^ 64; // xor
            }
// 7300   P = P + 1
            P++;
// 7310   MID$(PKTDAT$,P,1) = CHR$(T)
            PKTDAT[ P ] = T;
        }
// 7400 NEXT J
L7400:
    }
// 7420 CHK = (CHK + ((CHK AND 192) \ 64)) AND 63
//  check = tochar((s + ((s AND 192)/64)) AND 63)
    CHK = ( CHK + (( CHK & 192 ) / 64 ) & 63 );
// 7430 CHKSUM = ASC(MID$(RCVBUF$,J,1)) - 32
// 7450 IF CHKSUM <> CHK THEN TYP$ = "Q"
    if( CHK != ( RCVBUF[ loop ] - 32 ) )
    {
        return 'Q';
    }
// 7460 RETURN
    return TYP;
}

uint8_t kermit_len( uint8_t *str )
{
    uint8_t count = 0;
    while( 1 )
    {
        count++;
        if( str[ count ] == NUL )
        {
            return count;
        }
    }
}

void kermit_sendack( uint8_t *str )
{
// 8000 ' Routine to send an ACK and increment the packet number...
// 8010 D$ = ""
// 8020 TYP$ = "Y" : L = LEN(D$) : GOSUB 6000
    L = kermit_len( str );
    kermit_putpkt( 'Y' );
// 8030 N = (N + 1) AND 63
    N = ( N + 1 ) & 63;
// 8040 IF (N AND 3) = 0 THEN PRINT ".";
    if( ( N & 3 ) == 0 )
    {
        print_console( "." );
    }
// 8050 RETURN
}

// 9000 ' Error handler, nothing fancy...
// 9010 D$ = "Error " + STR$(ERR) + " at Line" + STR$(ERL)
// 9020 PRINT D$

uint8_t kermit_senderr( uint8_t *str )
{
// 9500 ' Error packet sender...
// 9520 L = LEN(D$) : TYP$ = "E" : GOSUB 6000
    L = kermit_len( str );
    kermit_putpkt( 'E' );
    return 'E';
}

// 9900 ' Normal exit point
// 9910 CLOSE
// 9920 PRINT CHR$(7);"(Done)"
// 9999 END
