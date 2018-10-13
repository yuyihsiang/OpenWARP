!--------------------------------------------------------------------------------------
!
!Copyright (C) 2014 TopCoder Inc., All Rights Reserved.
!
!--------------------------------------------------------------------------------------

!--------------------------------------------------------------------------------------
!
!   Copyright 2014 Ecole Centrale de Nantes, 1 rue de la No�, 44300 Nantes, France
!
!   Licensed under the Apache License, Version 2.0 (the "License");
!   you may not use this file except in compliance with the License.
!   You may obtain a copy of the License at
!
!       http://www.apache.org/licenses/LICENSE-2.0
!
!   Unless required by applicable law or agreed to in writing, software
!   distributed under the License is distributed on an "AS IS" BASIS,
!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!   See the License for the specific language governing permissions and
!   limitations under the License. 
!
!   Contributors list:
!   - G. Delhommeau
!   - P. Gu�vel
!   - J.C. Daubisse
!   - J. Singh  
!
!--------------------------------------------------------------------------------------

!   This module contains utilities that will be used to construct the influence matrix for a given
!   problem. It is used for a finite linear BVP problem.
!
! Changes in version 1.2 (Implementation of Higher Order Panel Methods)
!       Added COMMON_TYPE module as dependency
!
! Changes in version 1.3 (Dipoles Implementation in NEMOH)
!       Updated the subroutine to accept an additional parameter indicating the type
!       of derivative to perform
!
!   @author yedtoss
!   @version 1.3
MODULE COMPUTE_GREEN_FD

    USE COMMON_TYPE
    USE COM_VAR
    USE ELEMENTARY_FNS
    IMPLICIT NONE

CONTAINS
    !-------------------------------------------------------------------------------!
    SUBROUTINE VAVNSFD(deriv, KKK,AM0,AMH,NEXP,ISYM,SolverVar,ZIJ,KdNum,TD)

        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ
        INTEGER:: ISYM
        INTEGER:: KKK,I,J,IMXX,MK,NJJ,JJ,L,MH,MY,MZ,MJJ,KdNum,TD
        INTEGER:: KK(5)
        REAL:: DH,XOI,YOI,ZOI,XGI,YGI,ZGI
        REAL:: RR(5),DRX(5),DRY(5),DRZ(5)
        REAL:: PI,PI4,DPI,QPI,WH
        REAL:: TXN(5),TYN(5),TZN(5),AIJS(4),VXS(4),VYS(4),VZS(4)
        REAL:: A3J,A6J,A9J,ALDEN,ANL,ANLX,ANLY,ANLZ,ANTX,ANTY,ANTZ
        REAL:: ARG,ASRO,AT,ATX,ATY,ATZ,DAT,DDK,DEN,DENL,DENT,DK,DLOGG
        REAL:: ANT,DNL,DNT,DNTX,DNTY,DNTZ,DR,DS,GY,GYX,GYZ,GZAV,PJ,QJ,RJ,RO,SGN,W
        REAL:: GYY,XOJ,YOJ,ZOJ
        COMPLEX, DIMENSION(:, :):: ZIJ    
        REAL:: PCOS,PSIN

        REAL:: AM0,AMH
        REAL:: FS1(NFA,2),FS2(NFA,2)
        INTEGER::IJUMP,NEXP,NEXP1
        INTEGER::BX,BKL,IT,KE,KI,KJ1,KJ2,KJ3,KJ4,KL
        REAL::H,A,ADPI,ADPI2,AKH,COE1,COE2,COE3,COE4,EPS
        REAL:: VSX1(NFA,2),VSY1(NFA,2),VSZ1(NFA,2)
        REAL:: VSX2(NFA,2),VSY2(NFA,2),VSZ2(NFA,2)
        REAL:: ZMIII,ACT,AKP4,AKR,AKZ1,AKZ2,AKZ3,AKZ4,AQT,ASRO1,ASRO2
        REAL:: ASRO3,ASRO4,C1V3,C2V3,COF1,COF2,COF3,COF4
        REAL:: CSK,CT,ST,CVX,CVY,DD1,DD2,DD3,DD4,DSK,DXL,DYL
        REAL:: EPZ1,EPZ2,EPZ3,EPZ4,F1,F2,F3,FFS1,FFS2,FFS3,FFS4,FTS1,FTS2,FTS3,FTS4
        REAL:: OM,PD1X1,PD1X2,PD1X3,PD1X4,PD1Z1,PD1Z2, PD1Z3,PD1Z4,PD2X1,PD2X2
        REAL:: PD2X3,PD2X4,PD2Z1,PD2Z2,PD2Z3,PD2Z4
        REAL:: PSK,PSR1,PSR2,PSR3,PSR4,PSURR1,PSURR2,PSURR3,PSURR4,QJJJ,QTQQ
        REAL:: RO1,RO2,RO3,RO4,RRR,RR1,RR2,RR3,RR4,SCDS,SSDS,STSS
        REAL:: SQ,SIK,SCK,TETA,VR21,VR22,VR23,VR24
        REAL:: VX1,VX2,VX3,VX4,VY1,VY2,VY3,VY4,VZ1,VZ2,VZ3,VZ4
        REAL:: VXS1,VXS2,VXS3,VXS4,VZ11,VZ12,VZ13,VZ14,VZ21,VZ22,VZ23,VZ24
        REAL:: VYS1,VYS2,VYS3,VYS4,VZS1,VZS2,VZS3,VZS4
        REAL:: XL1,XL2,XL3,XPG,YPG,YMJJJ,ZL11,ZL12,ZL13,ZL14
        REAL:: ZL21,ZL22,ZL23,ZL24,ZL31,ZL32,ZL33,ZL34,ZPG1,ZPG2,ZPG3,ZPG4
        REAL:: ZZZ1,ZZZ2,ZZZ3,ZZZ4
        COMPLEX ZIJNS(4,5),CEX(4,5),GZ(4,5),CL(4,5)
        COMPLEX:: S1,ZV1,S2,ZV2,ZV3,ZV4,Z1,Z0,CL1,CL0,G1,G0
        COMPLEX:: CEX1,CEX0,AUX,ZAM,ZI,ZIRS,ZIRC
        REAL:: ZP(4),XFT(5),YFT(5),ZFT(5)


        TYPE(TempVar) :: SolverVar

        PI4=ATAN(1.)
        PI=4.*PI4
        DPI=2.*PI
        QPI=4.*PI

        DO J=1,IMX
        DO I=1,IMX

        NJJ=2*(NSYMY+1)
        DH=2*Depth
        MK=(-1)**(KKK+1)
        IF(KKK.EQ.1)IMXX=IMX
        IF(KKK.EQ.2)IMXX=IXX

        XOI=XG(I)
        YOI=YG(I)
        ZOI=ZG(I)
        XGI=XG(I)
        YGI=YG(I)
        ZGI=ZG(I)

!       REPALCE THE ORIGINAL VAVFD SUBROUTINE
        IF(KKK.EQ.1)THEN
            IF(I.LE.IMX)THEN
                IF(ZGI.GT.ZER)THEN
                    ZOI=ZER
                ELSE
                    ZOI=ZGI
                ENDIF
            ENDIF
        ELSE
            IF(I.LE.IMX)THEN
                IF(ZGI.GT.ZER)THEN
                    ZOI=20*ZER
                ELSE
                    ZOI=ZGI
                ENDIF
            ENDIF
        ENDIF
                                                         
        DO JJ=1,NJJ
            MJJ=(-1)**(JJ+1)
            MY=(-1)**(JJ/3+2)
            MZ=(-1)**(JJ/2+2)
            MH=(1-(-1)**(JJ/2+2))/2
            XOJ=XG(J)
            YOJ=YG(J)*MY
            ZOJ=ZG(J)*MZ-DH*MH
            A3J=XN(J)
            A6J=YN(J)*MY
            A9J=ZN(J)*MZ
            RO=SQRT((XOI-XOJ)**2+(YOI-YOJ)**2+(ZOI-ZOJ)**2)
            IF(RO.GT.7.*TDIS(J))THEN
                AIJS(JJ)=AIRE(J)/RO
                ASRO=AIJS(JJ)/RO**2
                VXS(JJ)=-(XOI-XOJ)*ASRO
                VYS(JJ)=-(YOI-YOJ)*ASRO
                VZS(JJ)=-(ZOI-ZOJ)*ASRO
            ELSE
                AIJS(JJ)=0.
                VXS(JJ)=0.
                VYS(JJ)=0.
                VZS(JJ)=0.
                KK(1)=M1(J)
                KK(2)=M2(J)
                KK(3)=M3(J)
                KK(4)=M4(J)
                KK(5)=KK(1)
                DO L=1,4
                    TXN(L)=X(KK(L))
                    TYN(L)=Y(KK(L))*MY
                    TZN(L)=Z(KK(L))*MZ-DH*MH
                END DO
                TXN(5)=TXN(1)
                TYN(5)=TYN(1)
                TZN(5)=TZN(1)
                DO L=1,4
                    RR(L)=SQRT((XOI-TXN(L))**2+(YOI-TYN(L))**2+(ZOI-TZN(L))**2)
                    DRX(L)=(XOI-TXN(L))/RR(L)
                    DRY(L)=(YOI-TYN(L))/RR(L)
                    DRZ(L)=(ZOI-TZN(L))/RR(L)
                END DO
             
                RR(5)=RR(1)
                DRX(5)=DRX(1)
                DRY(5)=DRY(1)
                DRZ(5)=DRZ(1)
                GZAV=(XOI-XOJ)*A3J+(YOI-YOJ)*A6J+(ZOI-ZOJ)*A9J
                DO L=1,4
                    DK=SQRT((TXN(L+1)-TXN(L))**2+(TYN(L+1)-TYN(L))**2+(TZN(L+1)-TZN(L))**2)
                    IF(DK.GE.1.E-3*TDIS(J))THEN
                        PJ=(TXN(L+1)-TXN(L))/DK
                        QJ=(TYN(L+1)-TYN(L))/DK
                        RJ=(TZN(L+1)-TZN(L))/DK
                        GYX=A6J*RJ-A9J*QJ
                        GYY=A9J*PJ-A3J*RJ
                        GYZ=A3J*QJ-A6J*PJ
                        GY=(XOI-TXN(L))*GYX+(YOI-TYN(L))*GYY+(ZOI-TZN(L))*GYZ
                        SGN=SIGN(1.,GZAV)
                        DDK=2.*DK
                        ANT=GY*DDK
                        DNT=(RR(L+1)+RR(L))**2-DK*DK+2.*ABS(GZAV)*(RR(L+1)+RR(L))
                        ARG=ANT/DNT
                        ANL=RR(L+1)+RR(L)+DK
                        DNL=RR(L+1)+RR(L)-DK
                        DEN=ANL/DNL
                        ALDEN=ALOG(DEN)
                        IF(ABS(GZAV).GE.1.E-4*TDIS(J))THEN
                            AT=ATAN(ARG)
                        ELSE
                            AT=0.
                        ENDIF
                        AIJS(JJ)=AIJS(JJ)+GY*ALDEN-2.*ABS(GZAV)*AT
                        DAT=2.*AT*SGN
                        ANTX=GYX*DDK
                        ANTY=GYY*DDK
                        ANTZ=GYZ*DDK
                        ANLX=DRX(L+1)+DRX(L)
                        ANLY=DRY(L+1)+DRY(L)
                        ANLZ=DRZ(L+1)+DRZ(L)
                        DR=2.*(RR(L+1)+RR(L)+ABS(GZAV))
                        DS=2.*(RR(L+1)+RR(L))*SGN
                        DNTX=DR*ANLX+A3J*DS
                        DNTY=DR*ANLY+A6J*DS
                        DNTZ=DR*ANLZ+A9J*DS
                        DENL=ANL*DNL
                        DENT=ANT*ANT+DNT*DNT
                        ATX=(ANTX*DNT-DNTX*ANT)/DENT
                        ATY=(ANTY*DNT-DNTY*ANT)/DENT
                        ATZ=(ANTZ*DNT-DNTZ*ANT)/DENT
                        DLOGG=(DNL-ANL)/DENL
                        VXS(JJ)=VXS(JJ)+GYX*ALDEN+GY*ANLX*DLOGG-2.*ABS(GZAV)*ATX-DAT*A3J
                        VYS(JJ)=VYS(JJ)+GYY*ALDEN+GY*ANLY*DLOGG-2.*ABS(GZAV)*ATY-DAT*A6J
                        VZS(JJ)=VZS(JJ)+GYZ*ALDEN+GY*ANLZ*DLOGG-2.*ABS(GZAV)*ATZ-DAT*A9J
                    ENDIF
                END DO
                IF(I.EQ.J.AND.JJ.EQ.1)THEN
                    VXS(1)=VXS(1)-DPI*A3J
                    VYS(1)=VYS(1)-DPI*A6J
                    VZS(1)=VZS(1)-DPI*A9J
                ELSE
                    AIJS(JJ)=AIJS(JJ)*MJJ
                    VXS(JJ)=VXS(JJ)*MJJ
                    VYS(JJ)=VYS(JJ)*MJJ
                    VZS(JJ)=VZS(JJ)*MJJ
                ENDIF
            ENDIF
        END DO
        IF(NSYMY.EQ.1)THEN
            W=AIJS(1)-MK*(AIJS(2)+AIJS(3))+AIJS(4)
            SolverVar%FSP=-W/QPI
            W=AIJS(1)-MK*(AIJS(2)-AIJS(3))-AIJS(4)
            SolverVar%FSM=-W/QPI
            W=VXS(1)-MK*(VXS(2)+VXS(3))+VXS(4)
            SolverVar%VSXP=-W/QPI
            W=VYS(1)-MK*(VYS(2)+VYS(3))+VYS(4)
            SolverVar%VSYP=-W/QPI
            W=VZS(1)-MK*(VZS(2)+VZS(3))+VZS(4)
            SolverVar%VSZP=-W/QPI
            W=VXS(1)-MK*(VXS(2)-VXS(3))-VXS(4)
            SolverVar%VSXM=-W/QPI
            W=VYS(1)-MK*(VYS(2)-VYS(3))-VYS(4)
            SolverVar%VSYM=-W/QPI
            W=VZS(1)-MK*(VZS(2)-VZS(3))-VZS(4)
            SolverVar%VSZM=-W/QPI
        ELSE
            W=AIJS(1)-MK*AIJS(2)
            SolverVar%FSP=-W/QPI
            SolverVar%FSM=SolverVar%FSP
            W=VXS(1)-MK*VXS(2)
            SolverVar%VSXP=-W/QPI
            SolverVar%VSXM=SolverVar%VSXP
            W=VYS(1)-MK*VYS(2)
            SolverVar%VSYP=-W/QPI
            SolverVar%VSYM=SolverVar%VSYP
            W=VZS(1)-MK*VZS(2)
            SolverVar%VSZP=-W/QPI
            SolverVar%VSZM=SolverVar%VSZP

            IF(deriv == 2) THEN

                SolverVar%VSXP = -SolverVar%VSXP
                SolverVar%VSXM=SolverVar%VSXP

                SolverVar%VSYP = -SolverVar%VSYP
                SolverVar%VSYM=SolverVar%VSYP

                SolverVar%VSZP=-(-VZS(1)-MK*VZS(2))/QPI
                SolverVar%VSZM=SolverVar%VSZP

            END IF
        ENDIF

!       REPALCE THE ORIGINAL VNSFD SUBROUTINE
        H=Depth
        ZI=(0.,1.)
        WH=DPI/SolverVar%T
        AKH=AMH*TANH(AMH)
        A=(AMH+AKH)**2/(H*(AMH**2-AKH**2+AKH))
        NEXP1=NEXP+1
        SolverVar%AMBDA(NEXP1)=0.
        SolverVar%AR(NEXP1)=2.
        ADPI2=-A/(8.*PI**2)
        ADPI=-A/(8*PI)
        COE1=ADPI2/AM0
        COE2=ADPI/AM0
        COE3=ADPI2
        COE4=ADPI
        ijump=1
        EPS=0.0001
        NJJ=NSYMY+1

        IF(I.LE.IMX)THEN
            ZMIII=ZGI
            IF(ZGI.GT.ZER)ZMIII=20*ZER
        ELSE
            ZMIII=20*ZER
        ENDIF
             
        DO JJ=1,NJJ
            BX=(-1)**(JJ+1)
            IF(ZGI.LT.ZER.AND.ZG(J).LT.ZER)THEN   !0000B
                QJJJ=BX*YN(J)
                YMJJJ=BX*YG(J)
                COF1=COE3*AIRE(J)
                COF2=COE4*AIRE(J)
                COF3=AM0*COF1
                COF4=AM0*COF2
                RRR=SQRT((XGI-XG(J))**2+(YGI-YMJJJ)**2)
                AKR=AM0*RRR
                ZZZ1=ZMIII+ZG(J)
                AKZ1=AM0*ZZZ1
                DD1=SQRT(RRR**2+ZZZ1**2)
                IF(DD1.GT.EPS)THEN
                    RR1=AM0*DD1
                    PSR1=PI/RR1
                    PSURR1=PI/RR1**3
                ELSE
                    PSR1=0.
                    PSURR1=0.
                ENDIF

                IF(AKZ1.GT.-1.5E-6)THEN             !0001B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                               !0001E
                    IF(AKZ1.GT.-16.)THEN             !0002B
                        IF(AKR.LT.99.7)THEN            !0003B
                            IF(AKZ1.LT.-1.E-2)THEN
                                KJ1=INT(8*(ALOG10(-AKZ1)+4.5))
                            ELSE
                                KJ1=INT(5*(ALOG10(-AKZ1)+6))
                            ENDIF
                            KJ1=MAX(KJ1,2)
                            KJ1=MIN(KJ1,TABULATION_JZ-1)
                            IF(AKR.LT.1.)THEN
                                KI=INT(5*(ALOG10(AKR+1.E-20)+6)+1)
                            ELSE
                                KI=INT(3*AKR+28)
                            ENDIF
                            KI=MAX(KI,2)
                            KI=MIN(KI,TABULATION_IR-1)
                            XL1=PL2(XR(KI),XR(KI+1),XR(KI-1),AKR)
                            XL2=PL2(XR(KI+1),XR(KI-1),XR(KI),AKR)
                            XL3=PL2(XR(KI-1),XR(KI),XR(KI+1),AKR)
                            ZL11=PL2(XZ(KJ1),XZ(KJ1+1),XZ(KJ1-1),AKZ1)
                            ZL21=PL2(XZ(KJ1+1),XZ(KJ1-1),XZ(KJ1),AKZ1)
                            ZL31=PL2(XZ(KJ1-1),XZ(KJ1),XZ(KJ1+1),AKZ1)
                            F1=XL1*APD1Z(KI-1,KJ1-1)+XL2*APD1Z(KI,KJ1-1)+ &
                                & XL3*APD1Z(KI+1,KJ1-1)
                            F2=XL1*APD1Z(KI-1,KJ1)+XL2*APD1Z(KI,KJ1)+ &
                                & XL3*APD1Z(KI+1,KJ1)
                            F3=XL1*APD1Z(KI-1,KJ1+1)+XL2*APD1Z(KI,KJ1+1)+ &
                                & XL3*APD1Z(KI+1,KJ1+1)
                            PD1Z1=ZL11*F1+ZL21*F2+ZL31*F3
                            F1=XL1*APD2Z(KI-1,KJ1-1)+XL2*APD2Z(KI,KJ1-1)+ &
                                & XL3*APD2Z(KI+1,KJ1-1)
                            F2=XL1*APD2Z(KI-1,KJ1)+XL2*APD2Z(KI,KJ1)+ &
                                & XL3*APD2Z(KI+1,KJ1)
                            F3=XL1*APD2Z(KI-1,KJ1+1)+XL2*APD2Z(KI,KJ1+1)+ &
                                & XL3*APD2Z(KI+1,KJ1+1)
                            PD2Z1=ZL11*F1+ZL21*F2+ZL31*F3
                        ELSE                           !0003E
                            EPZ1=EXP(AKZ1)
                            AKP4=AKR-PI4
                            SQ=SQRT(DPI/AKR)
                            CSK=COS(AKP4)
                            SIK=SIN(AKP4)
                            PSK=PI*SQ*SIK
                            SCK=SQ*CSK
                            PD1Z1=PSURR1*AKZ1-PSK*EPZ1
                            PD2Z1=EPZ1*SCK
                        ENDIF                         !0003F
                        VZ11=PD1Z1-PSURR1*AKZ1
                        VZ21=PD2Z1
                    ELSE                            !0002E
                        PD1Z1=PSURR1*AKZ1
                        PD2Z1=0.
                        VZ11=0.
                        VZ21=0.
                    ENDIF                           !0002F
                ENDIF                             !0001F
                ZZZ2=ZG(J)-ZMIII-2*H
                AKZ2=AM0*ZZZ2
                DD2=SQRT(RRR**2+ZZZ2**2)
                IF(DD2.GT.EPS)THEN
                    RR2=AM0*DD2
                    PSR2=PI/RR2
                    PSURR2=PI/RR2**3
                ELSE
                    PSR2=0.
                    PSURR2=0.
                ENDIF

                IF(AKZ2.GT.-1.5E-6)THEN            !0004B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                               !0004E
                    IF(AKZ2.GT.-16.)THEN             !0005B
                        IF(AKR.LT.99.7)THEN            !0006B
                            IF(AKZ2.LT.-1.E-2)THEN
                                KJ2=INT(8*(ALOG10(-AKZ2)+4.5))
                            ELSE
                                KJ2=INT(5*(ALOG10(-AKZ2)+6))
                            ENDIF
                            KJ2=MAX(KJ2,2)
                            KJ2=MIN(KJ2,45)
                            ZL12=PL2(XZ(KJ2),XZ(KJ2+1),XZ(KJ2-1),AKZ2)
                            ZL22=PL2(XZ(KJ2+1),XZ(KJ2-1),XZ(KJ2),AKZ2)
                            ZL32=PL2(XZ(KJ2-1),XZ(KJ2),XZ(KJ2+1),AKZ2)
                            F1=XL1*APD1Z(KI-1,KJ2-1)+XL2*APD1Z(KI,KJ2-1)+ &
                                & XL3*APD1Z(KI+1,KJ2-1)
                            F2=XL1*APD1Z(KI-1,KJ2)+XL2*APD1Z(KI,KJ2)+XL3*APD1Z(KI+1,KJ2)
                            F3=XL1*APD1Z(KI-1,KJ2+1)+XL2*APD1Z(KI,KJ2+1)+ &
                                & XL3*APD1Z(KI+1,KJ2+1)
                            PD1Z2=ZL12*F1+ZL22*F2+ZL32*F3
                            F1=XL1*APD2Z(KI-1,KJ2-1)+XL2*APD2Z(KI,KJ2-1)+ &
                                & XL3*APD2Z(KI+1,KJ2-1)
                            F2=XL1*APD2Z(KI-1,KJ2)+XL2*APD2Z(KI,KJ2)+XL3*APD2Z(KI+1,KJ2)
                            F3=XL1*APD2Z(KI-1,KJ2+1)+XL2*APD2Z(KI,KJ2+1)+ &
                                & XL3*APD2Z(KI+1,KJ2+1)
                            PD2Z2=ZL12*F1+ZL22*F2+ZL32*F3
                        ELSE                          !0006E
                            EPZ2=EXP(AKZ2)
                            PD1Z2=PSURR2*AKZ2-PSK*EPZ2
                            PD2Z2=EPZ2*SCK
                        ENDIF                         !0006F
                        VZ12=PD1Z2-PSURR2*AKZ2
                        VZ22=PD2Z2
                    ELSE                            !0005E
                        PD1Z2=PSURR2*AKZ2
                        PD2Z2=0.
                        VZ12=0.
                        VZ22=0.
                    ENDIF                            !0005F
                ENDIF                              !0004F
                ZZZ3=ZMIII-ZG(J)-2*H
                AKZ3=AM0*ZZZ3
                DD3=SQRT(RRR**2+ZZZ3**2)
                IF(DD3.GT.EPS)THEN
                    RR3=AM0*DD3
                    PSR3=PI/RR3
                    PSURR3=PI/RR3**3
                ELSE
                    PSR3=0.
                    PSURR3=0.
                ENDIF

                IF(AKZ3.GT.-1.5E-6)THEN   !0007B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                    !0007E
                    IF(AKZ3.GT.-16.)THEN    !0008B
                        IF(AKR.LT.99.7)THEN     !0009B
                            IF(AKZ3.LT.-1.E-2)THEN
                                KJ3=INT(8*(ALOG10(-AKZ3)+4.5))
                            ELSE
                                KJ3=INT(5*(ALOG10(-AKZ3)+6))
                            ENDIF
                            KJ3=MAX(KJ3,2)
                            KJ3=MIN(KJ3,45)
                            ZL13=PL2(XZ(KJ3),XZ(KJ3+1),XZ(KJ3-1),AKZ3)
                            ZL23=PL2(XZ(KJ3+1),XZ(KJ3-1),XZ(KJ3),AKZ3)
                            ZL33=PL2(XZ(KJ3-1),XZ(KJ3),XZ(KJ3+1),AKZ3)
                            F1=XL1*APD1Z(KI-1,KJ3-1)+XL2*APD1Z(KI,KJ3-1)+ &
                                & XL3*APD1Z(KI+1,KJ3-1)
                            F2=XL1*APD1Z(KI-1,KJ3)+XL2*APD1Z(KI,KJ3)+XL3*APD1Z(KI+1,KJ3)
                            F3=XL1*APD1Z(KI-1,KJ3+1)+XL2*APD1Z(KI,KJ3+1)+ &
                                & XL3*APD1Z(KI+1,KJ3+1)
                            PD1Z3=ZL13*F1+ZL23*F2+ZL33*F3
                            F1=XL1*APD2Z(KI-1,KJ3-1)+XL2*APD2Z(KI,KJ3-1)+ &
                                & XL3*APD2Z(KI+1,KJ3-1)
                            F2=XL1*APD2Z(KI-1,KJ3)+XL2*APD2Z(KI,KJ3)+XL3*APD2Z(KI+1,KJ3)
                            F3=XL1*APD2Z(KI-1,KJ3+1)+XL2*APD2Z(KI,KJ3+1)+ &
                                & XL3*APD2Z(KI+1,KJ3+1)
                            PD2Z3=ZL13*F1+ZL23*F2+ZL33*F3
                        ELSE                    !0009E
                            EPZ3=EXP(AKZ3)
                            PD1Z3=PSURR3*AKZ3-PSK*EPZ3
                            PD2Z3=EPZ3*SCK
                        ENDIF                   !0009F
                        VZ13=PD1Z3-PSURR3*AKZ3
                        VZ23=PD2Z3
                    ELSE                    !0008E
                        PD1Z3=PSURR3*AKZ3
                        PD2Z3=0.
                        VZ13=0.
                        VZ23=0.
                    ENDIF                    !0008F
                ENDIF                    !0007F
                ZZZ4=-ZG(J)-ZMIII-4*H
                AKZ4=AM0*ZZZ4
                DD4=SQRT(RRR**2+ZZZ4**2)
                IF(DD4.GT.EPS)THEN
                    RR4=AM0*DD4
                    PSR4=PI/RR4
                    PSURR4=PI/RR4**3
                ELSE
                    PSR4=0.
                    PSURR4=0.
                ENDIF

                IF(AKZ4.GT.-1.5E-6)THEN       !0010B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                         !0010E
                    IF(AKZ4.GT.-16.)THEN       !0011B
                        IF(AKR.LT.99.7)THEN      !0012B
                            IF(AKZ4.LT.-1.E-2)THEN
                                KJ4=INT(8*(ALOG10(-AKZ4)+4.5))
                            ELSE
                                KJ4=INT(5*(ALOG10(-AKZ4)+6))
                            ENDIF
                            KJ4=MAX(KJ4,2)
                            KJ4=MIN(KJ4,45)
                            ZL14=PL2(XZ(KJ4),XZ(KJ4+1),XZ(KJ4-1),AKZ4)
                            ZL24=PL2(XZ(KJ4+1),XZ(KJ4-1),XZ(KJ4),AKZ4)
                            ZL34=PL2(XZ(KJ4-1),XZ(KJ4),XZ(KJ4+1),AKZ4)
                            F1=XL1*APD1Z(KI-1,KJ4-1)+XL2*APD1Z(KI,KJ4-1)+ &
                                & XL3*APD1Z(KI+1,KJ4-1)
                            F2=XL1*APD1Z(KI-1,KJ4)+XL2*APD1Z(KI,KJ4)+XL3*APD1Z(KI+1,KJ4)
                            F3=XL1*APD1Z(KI-1,KJ4+1)+XL2*APD1Z(KI,KJ4+1)+ &
                                & XL3*APD1Z(KI+1,KJ4+1)
                            PD1Z4=ZL14*F1+ZL24*F2+ZL34*F3
                            F1=XL1*APD2Z(KI-1,KJ4-1)+XL2*APD2Z(KI,KJ4-1)+ &
                                & XL3*APD2Z(KI+1,KJ4-1)
                            F2=XL1*APD2Z(KI-1,KJ4)+XL2*APD2Z(KI,KJ4)+XL3*APD2Z(KI+1,KJ4)
                            F3=XL1*APD2Z(KI-1,KJ4+1)+XL2*APD2Z(KI,KJ4+1)+ &
                                & XL3*APD2Z(KI+1,KJ4+1)
                            PD2Z4=ZL14*F1+ZL24*F2+ZL34*F3
                        ELSE                     !0012E
                            EPZ4=EXP(AKZ4)
                            PD1Z4=PSURR4*AKZ4-PSK*EPZ4
                            PD2Z4=EPZ4*SCK
                        ENDIF                    !0012F
                        VZ14=PD1Z4-PSURR4*AKZ4
                        VZ24=PD2Z4
                    ELSE                       !0011E
                        PD1Z4=PSURR4*AKZ4
                        PD2Z4=0.
                        VZ14=0.
                        VZ24=0.
                    ENDIF                      !0011F
                ENDIF                      !0010F
                QTQQ=PD1Z1+PD1Z2+PD1Z3+PD1Z4
                FS1(J,JJ)=COF1*(QTQQ-PSR1-PSR2-PSR3-PSR4)
                STSS=PD2Z1+PD2Z2+PD2Z3+PD2Z4
                FS2(J,JJ)=COF2*STSS
                                
                IF(I.LE.IMX)THEN   !501 B
                    IF(RRR.GT.EPS)THEN !601B
                        IF(AKZ1.LE.-1.5E-6)THEN !701B
                            IF(AKZ1.GT.-16.)THEN  !801B
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ1-1)+XL2*APD1X(KI,KJ1-1)+ &
                                        & XL3*APD1X(KI+1,KJ1-1)
                                    F2=XL1*APD1X(KI-1,KJ1)+XL2*APD1X(KI,KJ1)+ &
                                        & XL3*APD1X(KI+1,KJ1)
                                    F3=XL1*APD1X(KI-1,KJ1+1)+XL2*APD1X(KI,KJ1+1)+ &
                                        & XL3*APD1X(KI+1,KJ1+1)
                                    PD1X1=ZL11*F1+ZL21*F2+ZL31*F3
                                    F1=XL1*APD2X(KI-1,KJ1-1)+XL2*APD2X(KI,KJ1-1)+ &
                                        & XL3*APD2X(KI+1,KJ1-1)
                                    F2=XL1*APD2X(KI-1,KJ1)+XL2*APD2X(KI,KJ1)+XL3*APD2X(KI+1,KJ1)
                                    F3=XL1*APD2X(KI-1,KJ1+1)+XL2*APD2X(KI,KJ1+1)+ &
                                        & XL3*APD2X(KI+1,KJ1+1)
                                    PD2X1=ZL11*F1+ZL21*F2+ZL31*F3
                                ELSE
                                    DSK=0.5/AKR
                                    SCDS=PI*SQ*(CSK-DSK*SIK)
                                    SSDS=SQ*(SIK+DSK*CSK)
                                    PD1X1=-PSURR1*AKR-EPZ1*SCDS
                                    PD2X1=EPZ1*SSDS
                                ENDIF
                                VR21=-PD2X1
                            ELSE !801E
                                PD1X1=-PSURR1*AKR
                                PD2X1=0.
                                VR21=0.
                            ENDIF   !801F
                        ENDIF !701F
                        IF(AKZ2.LE.-1.5E-6)THEN
                            IF(AKZ2.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ2-1)+XL2*APD1X(KI,KJ2-1)+ &
                                        & XL3*APD1X(KI+1,KJ2-1)
                                    F2=XL1*APD1X(KI-1,KJ2)+XL2*APD1X(KI,KJ2)+ &
                                        & XL3*APD1X(KI+1,KJ2)
                                    F3=XL1*APD1X(KI-1,KJ2+1)+XL2*APD1X(KI,KJ2+1)+ &
                                        &XL3*APD1X(KI+1,KJ2+1)
                                    PD1X2=ZL12*F1+ZL22*F2+ZL32*F3
                                    F1=XL1*APD2X(KI-1,KJ2-1)+XL2*APD2X(KI,KJ2-1)+ &
                                        & XL3*APD2X(KI+1,KJ2-1)
                                    F2=XL1*APD2X(KI-1,KJ2)+XL2*APD2X(KI,KJ2)+ &
                                        & XL3*APD2X(KI+1,KJ2)
                                    F3=XL1*APD2X(KI-1,KJ2+1)+XL2*APD2X(KI,KJ2+1)+ &
                                        & XL3*APD2X(KI+1,KJ2+1)
                                    PD2X2=ZL12*F1+ZL22*F2+ZL32*F3
                                ELSE
                                    PD1X2=-PSURR2*AKR-EPZ2*SCDS
                                    PD2X2=EPZ2*SSDS
                                ENDIF
                                VR22=-PD2X2
                            ELSE
                                PD1X2=-PSURR2*AKR
                                PD2X2=0.
                                VR22=0.
                            ENDIF
                        ENDIF
                        IF(AKZ3.LE.-1.5E-6)THEN
                            IF(AKZ3.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ3-1)+XL2*APD1X(KI,KJ3-1)+ &
                                        & XL3*APD1X(KI+1,KJ3-1)
                                    F2=XL1*APD1X(KI-1,KJ3)+XL2*APD1X(KI,KJ3)+ &
                                        & XL3*APD1X(KI+1,KJ3)
                                    F3=XL1*APD1X(KI-1,KJ3+1)+XL2*APD1X(KI,KJ3+1)+ &
                                        & XL3*APD1X(KI+1,KJ3+1)
                                    PD1X3=ZL13*F1+ZL23*F2+ZL33*F3
                                    F1=XL1*APD2X(KI-1,KJ3-1)+XL2*APD2X(KI,KJ3-1)+ &
                                        & XL3*APD2X(KI+1,KJ3-1)
                                    F2=XL1*APD2X(KI-1,KJ3)+XL2*APD2X(KI,KJ3)+ &
                                        & XL3*APD2X(KI+1,KJ3)
                                    F3=XL1*APD2X(KI-1,KJ3+1)+XL2*APD2X(KI,KJ3+1)+ &
                                        & XL3*APD2X(KI+1,KJ3+1)
                                    PD2X3=ZL13*F1+ZL23*F2+ZL33*F3
                                ELSE
                                    PD1X3=-PSURR3*AKR-EPZ3*SCDS
                                    PD2X3=EPZ3*SSDS
                                ENDIF
                                VR23=-PD2X3
                            ELSE
                                PD1X3=-PSURR3*AKR
                                PD2X3=0.
                                VR23=0.
                            ENDIF
                        ENDIF
                        IF(AKZ4.LE.-1.5E-6)THEN
                            IF(AKZ4.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ4-1)+XL2*APD1X(KI,KJ4-1)+ &
                                        & XL3*APD1X(KI+1,KJ4-1)
                                    F2=XL1*APD1X(KI-1,KJ4)+XL2*APD1X(KI,KJ4)+ &
                                        & XL3*APD1X(KI+1,KJ4)
                                    F3=XL1*APD1X(KI-1,KJ4+1)+XL2*APD1X(KI,KJ4+1)+ &
                                        & XL3*APD1X(KI+1,KJ4+1)
                                    PD1X4=ZL14*F1+ZL24*F2+ZL34*F3
                                    F1=XL1*APD2X(KI-1,KJ4-1)+XL2*APD2X(KI,KJ4-1)+ &
                                        & XL3*APD2X(KI+1,KJ4-1)
                                    F2=XL1*APD2X(KI-1,KJ4)+XL2*APD2X(KI,KJ4)+ &
                                        & XL3*APD2X(KI+1,KJ4)
                                    F3=XL1*APD2X(KI-1,KJ4+1)+XL2*APD2X(KI,KJ4+1)+ &
                                        & XL3*APD2X(KI+1,KJ4+1)
                                    PD2X4=ZL14*F1+ZL24*F2+ZL34*F3
                                ELSE
                                    PD1X4=-PSURR4*AKR-EPZ4*SCDS
                                    PD2X4=EPZ4*SSDS
                                ENDIF
                                VR24=-PD2X4
                            ELSE
                                PD1X4=-PSURR4*AKR
                                PD2X4=0.
                                VR24=0.
                            ENDIF
                        ENDIF
                        C1V3=-COF3*(PD1X1+PD1X2+PD1X3+PD1X4)
                        C2V3=COF4*(VR21+VR22+VR23+VR24)
                        CVX=(XGI-XG(J))/RRR
                        CVY=(YGI-YMJJJ)/RRR
                        VSX1(J,JJ)=C1V3*CVX
                        VSX2(J,JJ)=C2V3*CVX
                        VSY1(J,JJ)=C1V3*CVY
                        VSY2(J,JJ)=C2V3*CVY
                    ELSE                                 !601E
                        VSX1(J,JJ)=0.
                        VSX2(J,JJ)=0.
                        VSY1(J,JJ)=0.
                        VSY2(J,JJ)=0.
                    ENDIF                                 !601F
                    VSZ1(J,JJ)=COF3*(PD1Z1-PD1Z2+PD1Z3-PD1Z4)
                    VSZ2(J,JJ)=COF4*(VZ21-VZ22+VZ23-VZ24)
                ENDIF                                   !501F
    
                XPG=XGI-XG(J)
                YPG=YGI-YMJJJ
                ACT=-0.5*AIRE(J)/QPI
                DO KE=1,NEXP1
                    AQT=ACT*SolverVar%AR(KE)
                    ZPG1=ZMIII-2.*H+H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG2=-ZMIII-H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG3=-ZMIII-4.*H+H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG4=ZMIII+2.*H-H*SolverVar%AMBDA(KE)-ZG(J)
                    RR1=RRR**2+ZPG1**2
                    RO1=SQRT(RR1)
                    IF(RO1.GT.EPS)THEN
                        FTS1=AQT/RO1
                        ASRO1=FTS1/RR1
                    ELSE
                        FTS1=0.
                        ASRO1=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS1=-XPG*ASRO1
                        VYS1=-YPG*ASRO1
                        VZS1=-ZPG1*ASRO1
                    ENDIF
                    RR2=RRR**2+ZPG2**2
                    RO2=SQRT(RR2)
                    IF(RO2.GT.EPS)THEN
                        FTS2=AQT/RO2
                        ASRO2=FTS2/RR2
                    ELSE
                        FTS2=0.
                        ASRO2=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS2=-XPG*ASRO2
                        VYS2=-YPG*ASRO2
                        VZS2=-ZPG2*ASRO2
                    ENDIF
                    RR3=RRR**2+ZPG3**2
                    RO3=SQRT(RR3)
                    IF(RO3.GT.EPS)THEN
                        FTS3=AQT/RO3
                        ASRO3=FTS3/RR3
                    ELSE
                        FTS3=0.
                        ASRO3=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS3=-XPG*ASRO3
                        VYS3=-YPG*ASRO3
                        VZS3=-ZPG3*ASRO3
                    ENDIF
                    RR4=RRR**2+ZPG4**2
                    RO4=SQRT(RR4)
                    IF(RO4.GT.EPS)THEN
                        FTS4=AQT/RO4
                        ASRO4=FTS4/RR4
                    ELSE
                        FTS4=0.
                        ASRO4=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS4=-XPG*ASRO4
                        VYS4=-YPG*ASRO4
                        VZS4=-ZPG4*ASRO4
                    ENDIF
                    FS1(J,JJ)=FS1(J,JJ)+FTS1+FTS2+FTS3+FTS4
                    IF(I.LE.IMX)THEN
                        VSX1(J,JJ)=VSX1(J,JJ)+(VXS1+VXS2+VXS3+VXS4)
                        VSY1(J,JJ)=VSY1(J,JJ)+(VYS1+VYS2+VYS3+VYS4)
                        VSZ1(J,JJ)=VSZ1(J,JJ)+(VZS1-VZS2-VZS3+VZS4)
                    ENDIF
                END DO
            ELSE !0000E

                FS1(J,JJ)=0.
                FS2(J,JJ)=0.
                VSX1(J,JJ)=0.
                VSX2(J,JJ)=0.
                VSY1(J,JJ)=0.
                VSY2(J,JJ)=0.
                VSZ1(J,JJ)=0.
                VSZ2(J,JJ)=0.
                KK(1)=M1(J)
                KK(2)=M2(J)
                KK(3)=M3(J)
                KK(4)=M4(J)
                KK(5)=KK(1)
                DO IT=1,SolverVar%NQ
                    TETA=SolverVar%QQ(IT)
                    CT=COS(TETA)
                    ST=SIN(TETA)
                    DO L=1,4
                        OM=(XGI-X(KK(L)))*CT+(YGI-BX*Y(KK(L)))*ST
                        ZIJNS(1,L)=AM0*(Z(KK(L))+ZMIII+ZI*OM)
                        ZIJNS(2,L)=AM0*(Z(KK(L))-ZMIII-2*H+ZI*OM)
                        ZIJNS(3,L)=AM0*(ZMIII-Z(KK(L))-2*H+ZI*OM)
                        ZIJNS(4,L)=AM0*(-Z(KK(L))-ZMIII-4*H+ZI*OM)
                        DO KL=1,4
                            IF(REAL(ZIJNS(KL,L)).GT.-25.)THEN
                                CEX(KL,L)=CEXP(ZIJNS(KL,L))
                            ELSE
                                CEX(KL,L)=(0.,0.)
                            ENDIF
                            GZ(KL,L)=GG(ZIJNS(KL,L),CEX(KL,L))
                            CL(KL,L)=CLOG(-ZIJNS(KL,L))
                        END DO
                    END DO
                    DO KL=1,4
                        ZIJNS(KL,5)=ZIJNS(KL,1)
                        CEX(KL,5)=CEX(KL,1)
                        GZ(KL,5)=GZ(KL,1)
                        CL(KL,5)=CL(KL,1)
                    END DO
                    S1=(0.,0.)
                    S2=(0.,0.)
                    ZV1=(0.,0.)
                    ZV2=(0.,0.)
                    ZV3=(0.,0.)
                    ZV4=(0.,0.)
                    ZIRS=ZI*ZN(J)*ST
                    ZIRC=ZI*ZN(J)*CT
                    DO L=1,4
                        DXL=(X(KK(L+1))-X(KK(L)))
                        DYL=(Y(KK(L+1))-Y(KK(L)))*BX
                        DO KL=1,4
                            BKL=(-1)**(KL+1)
                            IF(KL.LT.3)THEN
                                AUX=DXL*(YN(J)*BX-ZIRS)-DYL*(XN(J)-ZIRC)
                            ELSE
                                AUX=DXL*(-YN(J)*BX-ZIRS)-DYL*(-XN(J)-ZIRC)
                            ENDIF
                            Z1=ZIJNS(KL,L+1)
                            Z0=ZIJNS(KL,L)
                            CL1=CL(KL,L+1)
                            CL0=CL(KL,L)
                            G1=GZ(KL,L+1)
                            G0=GZ(KL,L)
                            CEX1=CEX(KL,L+1)
                            CEX0=CEX(KL,L)
                            ZAM=Z1-Z0
                            IF(ABS(AIMAG(ZAM)).LT.EPS.AND.ABS(REAL(ZAM)).LT.EPS)THEN
                                S1=S1+AUX*(G1+G0+CL1+CL0)*0.5
                                ZV1=ZV1+AUX*BKL*(G1+G0)*0.5
                                ZV3=ZV3+AUX*(G1+G0)*0.5
                                S2=S2+AUX*(CEX1+CEX0)*0.5
                                ZV2=ZV2+AUX*BKL*(CEX1+CEX0)*0.5
                                ZV4=ZV4+AUX*(CEX1+CEX0)*0.5
                            ELSE
                                S1=S1+AUX*(G1-G0+CL1-CL0+Z1*CL1-Z0*CL0-ZAM)/ZAM
                                ZV1=ZV1+AUX*BKL*(G1-G0+CL1-CL0)/ZAM
                                ZV3=ZV3+AUX*(G1-G0+CL1-CL0)/ZAM
                                S2=S2+AUX*(CEX1-CEX0)/ZAM
                                ZV2=ZV2+AUX*BKL*(CEX1-CEX0)/ZAM
                                ZV4=ZV4+AUX*(CEX1-CEX0)/ZAM
                            ENDIF
                        END DO
                    END DO
                    FS1(J,JJ)=FS1(J,JJ)+SolverVar%CQ(IT)*REAL(S1)*COE1*BX
                    FS2(J,JJ)=FS2(J,JJ)+SolverVar%CQ(IT)*REAL(S2)*COE2*BX
                    VSX1(J,JJ)=VSX1(J,JJ)-SolverVar%CQ(IT)*CT*AIMAG(ZV3)*COE3*BX
                    VSX2(J,JJ)=VSX2(J,JJ)-SolverVar%CQ(IT)*CT*AIMAG(ZV4)*COE4*BX
                    VSY1(J,JJ)=VSY1(J,JJ)-SolverVar%CQ(IT)*ST*AIMAG(ZV3)*COE3*BX
                    VSY2(J,JJ)=VSY2(J,JJ)-SolverVar%CQ(IT)*ST*AIMAG(ZV4)*COE4*BX
                    VSZ1(J,JJ)=VSZ1(J,JJ)+SolverVar%CQ(IT)*REAL(ZV1)*COE3*BX
                    VSZ2(J,JJ)=VSZ2(J,JJ)+SolverVar%CQ(IT)*REAL(ZV2)*COE4*BX
                END DO
                ZP(1)=-ZMIII
                ZP(2)=ZMIII+2*H
                ZP(3)=ZMIII-2.*H
                ZP(4)=-ZMIII-4*H
                DO L=1,5
                    XFT(L)=X(KK(L))
                    YFT(L)=Y(KK(L))
                    ZFT(L)=Z(KK(L))
                END DO
                DO KE=1,NEXP1
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(1)-H*SolverVar%AMBDA(KE),FFS1,VX1,VY1,VZ1)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(2)-H*SolverVar%AMBDA(KE),FFS2,VX2,VY2,VZ2)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(3)+H*SolverVar%AMBDA(KE),FFS3,VX3,VY3,VZ3)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(4)+H*SolverVar%AMBDA(KE),FFS4,VX4,VY4,VZ4)
                    FS1(J,JJ)=FS1(J,JJ)+(FFS1+FFS2+FFS3+FFS4)*SolverVar%AR(KE)
                    IF(I.LE.IMX)THEN
                        VSX1(J,JJ)=VSX1(J,JJ)+(VX1+VX2+VX3+VX4)*SolverVar%AR(KE)
                        VSY1(J,JJ)=VSY1(J,JJ)+(VY1+VY2+VY3+VY4)*SolverVar%AR(KE)
                        VSZ1(J,JJ)=VSZ1(J,JJ)+(-VZ1+VZ2+VZ3-VZ4)*SolverVar%AR(KE)
                    ENDIF
                END DO

            ENDIF !0000F
        END DO

        IF(NSYMY.EQ.1)THEN  !101B
        
            SolverVar%SM1=SolverVar%FSM+FS1(J,1)-FS1(J,2)
            SolverVar%SP1=SolverVar%FSP+FS1(J,1)+FS1(J,2)
            SolverVar%SM2=FS2(J,1)-FS2(J,2)
            SolverVar%SP2=FS2(J,1)+FS2(J,2)
            SolverVar%VSXP1=SolverVar%VSXP+VSX1(J,1)+VSX1(J,2)
            SolverVar%VSXM1=SolverVar%VSXM+VSX1(J,1)-VSX1(J,2)
            SolverVar%VSYP1=SolverVar%VSYP+VSY1(J,1)+VSY1(J,2)
            SolverVar%VSYM1=SolverVar%VSYM+VSY1(J,1)-VSY1(J,2)
            SolverVar%VSZP1=SolverVar%VSZP+VSZ1(J,1)+VSZ1(J,2)
            SolverVar%VSZM1=SolverVar%VSZM+VSZ1(J,1)-VSZ1(J,2)
            SolverVar%VSXP2=VSX2(J,1)+VSX2(J,2)
            SolverVar%VSXM2=VSX2(J,1)-VSX2(J,2)
            SolverVar%VSYP2=VSY2(J,1)+VSY2(J,2)
            SolverVar%VSYM2=VSY2(J,1)-VSY2(J,2)
            SolverVar%VSZP2=VSZ2(J,1)+VSZ2(J,2)
            SolverVar%VSZM2=VSZ2(J,1)-VSZ2(J,2)
        ELSE      !101E
            SolverVar%SP1=SolverVar%FSP+FS1(J,1)
            SolverVar%SM1=SolverVar%SP1
            SolverVar%SP2=FS2(J,1)
            SolverVar%SM2=SolverVar%SP2
            SolverVar%VSXP1=SolverVar%VSXP+VSX1(J,1)
            SolverVar%VSXM1=SolverVar%VSXP1
            SolverVar%VSYP1=SolverVar%VSYP+VSY1(J,1)
            SolverVar%VSYM1=SolverVar%VSYP1
            SolverVar%VSZP1=SolverVar%VSZP+VSZ1(J,1)
            SolverVar%VSZM1=SolverVar%VSZP1
            SolverVar%VSXP2=VSX2(J,1)
            SolverVar%VSXM2=SolverVar%VSXP2
            SolverVar%VSYP2=VSY2(J,1)
            SolverVar%VSYM2=SolverVar%VSYP2
            SolverVar%VSZP2=VSZ2(J,1)
            SolverVar%VSZM2=SolverVar%VSZP2

            ! It is assumed VVV has been run with deriv == 2 also
            IF(deriv == 2) THEN

                SolverVar%VSXP1=SolverVar%VSXP - VSX1(J,1)
                SolverVar%VSXM1=SolverVar%VSXP1

                SolverVar%VSYP1=SolverVar%VSYP-VSY1(J,1)
                SolverVar%VSYM1=SolverVar%VSYP1

                SolverVar%VSZP1=SolverVar%VSZP - VSZ1(J,1)
                SolverVar%VSZM1=SolverVar%VSZP1

                SolverVar%VSXP2=-VSX2(J,1)
                SolverVar%VSXM2=SolverVar%VSXP2

                SolverVar%VSYP2 = -VSY2(J,1)
                SolverVar%VSYM2=SolverVar%VSYP2

                SolverVar%VSZP2 = -VSZ2(J,1)
                SolverVar%VSZM2=SolverVar%VSZP2

            END IF
        ENDIF !101F

        IF(KDNUM.EQ.1) THEN
            IF(ISYM.EQ.1)THEN

                PCOS=SolverVar%VSXP1*XN(I)+SolverVar%VSYP1*YN(I)+SolverVar%VSZP1*ZN(I)
                PSIN=SolverVar%VSXP2*XN(I)+SolverVar%VSYP2*YN(I)+SolverVar%VSZP2*ZN(I)

            ELSE

                PCOS=SolverVar%VSXM1*XN(I)+SolverVar%VSYM1*YN(I)+SolverVar%VSZM1*ZN(I)
                PSIN=SolverVar%VSXM2*XN(I)+SolverVar%VSYM2*YN(I)+SolverVar%VSZM2*ZN(I)

            END IF

            ZIJ(I,J)=CMPLX(PCOS,PSIN)

        ELSE

            IF(ProblemSavedAt(SolverVar%ProblemNumber) == -1 ) THEN
                SM1Cache(I, J, TD) = SolverVar%SM1
                SM2Cache(I, J, TD) = SolverVar%SM2
                SP1Cache(I, J, TD) = SolverVar%SP1
                SP2Cache(I, J, TD) = SolverVar%SP2
            END IF

        ENDIF
        END DO
        END DO

        RETURN
    END SUBROUTINE
    !-------------------------------------------------------------------------------!

    !-------------------------------------------------------------------------------!
    SUBROUTINE VAVFD(deriv, KKK,XGI,YGI,ZGI,ISP,IFP,SolverVar)

        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ
        INTEGER:: ISP,IFP
        INTEGER:: KKK,I,J,IMXX,MK,NJJ,JJ,L,MH,MY,MZ,MJJ
        INTEGER:: KK(5)
        REAL:: DH,XOI,YOI,ZOI,XGI,YGI,ZGI
        REAL:: RR(5),DRX(5),DRY(5),DRZ(5)
        REAL:: PI,PI4,DPI,QPI
        REAL:: TXN(5),TYN(5),TZN(5),AIJS(4),VXS(4),VYS(4),VZS(4)
        REAL:: A3J,A6J,A9J,ALDEN,ANL,ANLX,ANLY,ANLZ,ANTX,ANTY,ANTZ
        REAL:: ARG,ASRO,AT,ATX,ATY,ATZ,DAT,DDK,DEN,DENL,DENT,DK,DLOGG
        REAL:: ANT,DNL,DNT,DNTX,DNTY,DNTZ,DR,DS,GY,GYX,GYZ,GZ,PJ,QJ,RJ,RO,SGN,W
        REAL:: GYY,XOJ,YOJ,ZOJ
        TYPE(TempVar) :: SolverVar

        PI4=ATAN(1.)
        PI=4.*PI4
        DPI=2.*PI
        QPI=4.*PI
        NJJ=2*(NSYMY+1)
        DH=2*Depth
        MK=(-1)**(KKK+1)
        IF(KKK.EQ.1)IMXX=IMX
        IF(KKK.EQ.2)IMXX=IXX

        I=ISP
        J=IFP
        XOI=XGI
        YOI=YGI
        IF(KKK.EQ.1)THEN
            IF(I.LE.IMX)THEN
                IF(ZGI.GT.ZER)THEN
                    ZOI=ZER
                ELSE
                    ZOI=ZGI
                ENDIF
            ENDIF
        ELSE
            IF(I.LE.IMX)THEN
                IF(ZGI.GT.ZER)THEN
                    ZOI=20*ZER
                ELSE
                    ZOI=ZGI
                ENDIF
            ENDIF
        ENDIF
                                                         
        DO JJ=1,NJJ
            MJJ=(-1)**(JJ+1)
            MY=(-1)**(JJ/3+2)
            MZ=(-1)**(JJ/2+2)
            MH=(1-(-1)**(JJ/2+2))/2
            XOJ=XG(J)
            YOJ=YG(J)*MY
            ZOJ=ZG(J)*MZ-DH*MH
            A3J=XN(J)
            A6J=YN(J)*MY
            A9J=ZN(J)*MZ
            RO=SQRT((XOI-XOJ)**2+(YOI-YOJ)**2+(ZOI-ZOJ)**2)
            IF(RO.GT.7.*TDIS(J))THEN
                AIJS(JJ)=AIRE(J)/RO
                ASRO=AIJS(JJ)/RO**2
                VXS(JJ)=-(XOI-XOJ)*ASRO
                VYS(JJ)=-(YOI-YOJ)*ASRO
                VZS(JJ)=-(ZOI-ZOJ)*ASRO
            ELSE
                AIJS(JJ)=0.
                VXS(JJ)=0.
                VYS(JJ)=0.
                VZS(JJ)=0.
                KK(1)=M1(J)
                KK(2)=M2(J)
                KK(3)=M3(J)
                KK(4)=M4(J)
                KK(5)=KK(1)
                DO L=1,4
                    TXN(L)=X(KK(L))
                    TYN(L)=Y(KK(L))*MY
                    TZN(L)=Z(KK(L))*MZ-DH*MH
                END DO
                TXN(5)=TXN(1)
                TYN(5)=TYN(1)
                TZN(5)=TZN(1)
                DO L=1,4
                    RR(L)=SQRT((XOI-TXN(L))**2+(YOI-TYN(L))**2+(ZOI-TZN(L))**2)
                    DRX(L)=(XOI-TXN(L))/RR(L)
                    DRY(L)=(YOI-TYN(L))/RR(L)
                    DRZ(L)=(ZOI-TZN(L))/RR(L)
                END DO
             
                RR(5)=RR(1)
                DRX(5)=DRX(1)
                DRY(5)=DRY(1)
                DRZ(5)=DRZ(1)
                GZ=(XOI-XOJ)*A3J+(YOI-YOJ)*A6J+(ZOI-ZOJ)*A9J
                DO L=1,4
                    DK=SQRT((TXN(L+1)-TXN(L))**2+(TYN(L+1)-TYN(L))**2+(TZN(L+1)-TZN(L))**2)
                    IF(DK.GE.1.E-3*TDIS(J))THEN
                        PJ=(TXN(L+1)-TXN(L))/DK
                        QJ=(TYN(L+1)-TYN(L))/DK
                        RJ=(TZN(L+1)-TZN(L))/DK
                        GYX=A6J*RJ-A9J*QJ
                        GYY=A9J*PJ-A3J*RJ
                        GYZ=A3J*QJ-A6J*PJ
                        GY=(XOI-TXN(L))*GYX+(YOI-TYN(L))*GYY+(ZOI-TZN(L))*GYZ
                        SGN=SIGN(1.,GZ)
                        DDK=2.*DK
                        ANT=GY*DDK
                        DNT=(RR(L+1)+RR(L))**2-DK*DK+2.*ABS(GZ)*(RR(L+1)+RR(L))
                        ARG=ANT/DNT
                        ANL=RR(L+1)+RR(L)+DK
                        DNL=RR(L+1)+RR(L)-DK
                        DEN=ANL/DNL
                        ALDEN=ALOG(DEN)
                        IF(ABS(GZ).GE.1.E-4*TDIS(J))THEN
                            AT=ATAN(ARG)
                        ELSE
                            AT=0.
                        ENDIF
                        AIJS(JJ)=AIJS(JJ)+GY*ALDEN-2.*ABS(GZ)*AT
                        DAT=2.*AT*SGN
                        ANTX=GYX*DDK
                        ANTY=GYY*DDK
                        ANTZ=GYZ*DDK
                        ANLX=DRX(L+1)+DRX(L)
                        ANLY=DRY(L+1)+DRY(L)
                        ANLZ=DRZ(L+1)+DRZ(L)
                        DR=2.*(RR(L+1)+RR(L)+ABS(GZ))
                        DS=2.*(RR(L+1)+RR(L))*SGN
                        DNTX=DR*ANLX+A3J*DS
                        DNTY=DR*ANLY+A6J*DS
                        DNTZ=DR*ANLZ+A9J*DS
                        DENL=ANL*DNL
                        DENT=ANT*ANT+DNT*DNT
                        ATX=(ANTX*DNT-DNTX*ANT)/DENT
                        ATY=(ANTY*DNT-DNTY*ANT)/DENT
                        ATZ=(ANTZ*DNT-DNTZ*ANT)/DENT
                        DLOGG=(DNL-ANL)/DENL
                        VXS(JJ)=VXS(JJ)+GYX*ALDEN+GY*ANLX*DLOGG-2.*ABS(GZ)*ATX-DAT*A3J
                        VYS(JJ)=VYS(JJ)+GYY*ALDEN+GY*ANLY*DLOGG-2.*ABS(GZ)*ATY-DAT*A6J
                        VZS(JJ)=VZS(JJ)+GYZ*ALDEN+GY*ANLZ*DLOGG-2.*ABS(GZ)*ATZ-DAT*A9J
                    ENDIF
                END DO
                IF(I.EQ.J.AND.JJ.EQ.1)THEN
                    VXS(1)=VXS(1)-DPI*A3J
                    VYS(1)=VYS(1)-DPI*A6J
                    VZS(1)=VZS(1)-DPI*A9J
                ELSE
                    AIJS(JJ)=AIJS(JJ)*MJJ
                    VXS(JJ)=VXS(JJ)*MJJ
                    VYS(JJ)=VYS(JJ)*MJJ
                    VZS(JJ)=VZS(JJ)*MJJ
                ENDIF
            ENDIF
        END DO
        IF(NSYMY.EQ.1)THEN
            W=AIJS(1)-MK*(AIJS(2)+AIJS(3))+AIJS(4)
            SolverVar%FSP=-W/QPI
            W=AIJS(1)-MK*(AIJS(2)-AIJS(3))-AIJS(4)
            SolverVar%FSM=-W/QPI
            W=VXS(1)-MK*(VXS(2)+VXS(3))+VXS(4)
            SolverVar%VSXP=-W/QPI
            W=VYS(1)-MK*(VYS(2)+VYS(3))+VYS(4)
            SolverVar%VSYP=-W/QPI
            W=VZS(1)-MK*(VZS(2)+VZS(3))+VZS(4)
            SolverVar%VSZP=-W/QPI
            W=VXS(1)-MK*(VXS(2)-VXS(3))-VXS(4)
            SolverVar%VSXM=-W/QPI
            W=VYS(1)-MK*(VYS(2)-VYS(3))-VYS(4)
            SolverVar%VSYM=-W/QPI
            W=VZS(1)-MK*(VZS(2)-VZS(3))-VZS(4)
            SolverVar%VSZM=-W/QPI
        ELSE
            W=AIJS(1)-MK*AIJS(2)
            SolverVar%FSP=-W/QPI
            SolverVar%FSM=SolverVar%FSP
            W=VXS(1)-MK*VXS(2)
            SolverVar%VSXP=-W/QPI
            SolverVar%VSXM=SolverVar%VSXP
            W=VYS(1)-MK*VYS(2)
            SolverVar%VSYP=-W/QPI
            SolverVar%VSYM=SolverVar%VSYP
            W=VZS(1)-MK*VZS(2)
            SolverVar%VSZP=-W/QPI
            SolverVar%VSZM=SolverVar%VSZP

            IF(deriv == 2) THEN

                SolverVar%VSXP = -SolverVar%VSXP
                SolverVar%VSXM=SolverVar%VSXP

                SolverVar%VSYP = -SolverVar%VSYP
                SolverVar%VSYM=SolverVar%VSYP

                SolverVar%VSZP=-(-VZS(1)-MK*VZS(2))/QPI
                SolverVar%VSZM=SolverVar%VSZP

            END IF
        ENDIF

        RETURN
    END SUBROUTINE
    !-------------------------------------------------------------------------------!
                                                                      
    SUBROUTINE VNSFD(deriv, AM0,AMH,NEXP,ISP,IFP,XGI,YGI,ZGI,SolverVar)
  
        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ

        INTEGER::ISP,IFP
        REAL:: AM0,AMH,XGI,YGI,ZGI
        REAL:: FS1(NFA,2),FS2(NFA,2)
        INTEGER::I,J,JJ,IJUMP,NJJ,NEXP,NEXP1
        INTEGER::KK(5),BX,BKL,IT,KE,KI,KJ1,KJ2,KJ3,KJ4,KL,L
        REAL::H,A,ADPI,ADPI2,AKH,COE1,COE2,COE3,COE4,EPS
        REAL::PI,PI4,DPI,QPI,WH
        REAL:: VSX1(NFA,2),VSY1(NFA,2),VSZ1(NFA,2)
        REAL:: VSX2(NFA,2),VSY2(NFA,2),VSZ2(NFA,2)
        REAL:: ZMIII,ACT,AKP4,AKR,AKZ1,AKZ2,AKZ3,AKZ4,AQT,ASRO1,ASRO2
        REAL:: ASRO3,ASRO4,C1V3,C2V3,COF1,COF2,COF3,COF4
        REAL:: CSK,CT,ST,CVX,CVY,DD1,DD2,DD3,DD4,DSK,DXL,DYL
        REAL:: EPZ1,EPZ2,EPZ3,EPZ4,F1,F2,F3,FFS1,FFS2,FFS3,FFS4,FTS1,FTS2,FTS3,FTS4
        REAL:: OM,PD1X1,PD1X2,PD1X3,PD1X4,PD1Z1,PD1Z2, PD1Z3,PD1Z4,PD2X1,PD2X2
        REAL:: PD2X3,PD2X4,PD2Z1,PD2Z2,PD2Z3,PD2Z4
        REAL:: PSK,PSR1,PSR2,PSR3,PSR4,PSURR1,PSURR2,PSURR3,PSURR4,QJJJ,QTQQ
        REAL:: RO1,RO2,RO3,RO4,RRR,RR1,RR2,RR3,RR4,SCDS,SSDS,STSS
        REAL:: SQ,SIK,SCK,TETA,VR21,VR22,VR23,VR24
        REAL:: VX1,VX2,VX3,VX4,VY1,VY2,VY3,VY4,VZ1,VZ2,VZ3,VZ4
        REAL:: VXS1,VXS2,VXS3,VXS4,VZ11,VZ12,VZ13,VZ14,VZ21,VZ22,VZ23,VZ24
        REAL:: VYS1,VYS2,VYS3,VYS4,VZS1,VZS2,VZS3,VZS4
        REAL:: XL1,XL2,XL3,XPG,YPG,YMJJJ,ZL11,ZL12,ZL13,ZL14
        REAL:: ZL21,ZL22,ZL23,ZL24,ZL31,ZL32,ZL33,ZL34,ZPG1,ZPG2,ZPG3,ZPG4
        REAL:: ZZZ1,ZZZ2,ZZZ3,ZZZ4
        COMPLEX ZIJ(4,5),CEX(4,5),GZ(4,5),CL(4,5)
        COMPLEX:: S1,ZV1,S2,ZV2,ZV3,ZV4,Z1,Z0,CL1,CL0,G1,G0
        COMPLEX:: CEX1,CEX0,AUX,ZAM,ZI,ZIRS,ZIRC
        REAL:: ZP(4),XFT(5),YFT(5),ZFT(5)
        TYPE(TempVar) :: SolverVar

        PI4=ATAN(1.)
        PI=4.*ATAN(1.)
        DPI=2.*PI
        QPI=4.*PI
        H=Depth
        ZI=(0.,1.)
        WH=DPI/SolverVar%T
        AKH=AMH*TANH(AMH)
        A=(AMH+AKH)**2/(H*(AMH**2-AKH**2+AKH))
        NEXP1=NEXP+1
        SolverVar%AMBDA(NEXP1)=0.
        SolverVar%AR(NEXP1)=2.
        ADPI2=-A/(8.*PI**2)
        ADPI=-A/(8*PI)
        COE1=ADPI2/AM0
        COE2=ADPI/AM0
        COE3=ADPI2
        COE4=ADPI
        ijump=1
        EPS=0.0001
        NJJ=NSYMY+1

        I=ISP  !source point N
        J=IFP  ! observation point

        IF(I.LE.IMX)THEN
            ZMIII=ZGI
            IF(ZGI.GT.ZER)ZMIII=20*ZER
        ELSE
            ZMIII=20*ZER
        ENDIF
             
        DO JJ=1,NJJ
            BX=(-1)**(JJ+1)
            IF(ZGI.LT.ZER.AND.ZG(J).LT.ZER)THEN   !0000B
                QJJJ=BX*YN(J)
                YMJJJ=BX*YG(J)
                COF1=COE3*AIRE(J)
                COF2=COE4*AIRE(J)
                COF3=AM0*COF1
                COF4=AM0*COF2
                RRR=SQRT((XGI-XG(J))**2+(YGI-YMJJJ)**2)
                AKR=AM0*RRR
                ZZZ1=ZMIII+ZG(J)
                AKZ1=AM0*ZZZ1
                DD1=SQRT(RRR**2+ZZZ1**2)
                IF(DD1.GT.EPS)THEN
                    RR1=AM0*DD1
                    PSR1=PI/RR1
                    PSURR1=PI/RR1**3
                ELSE
                    PSR1=0.
                    PSURR1=0.
                ENDIF

                IF(AKZ1.GT.-1.5E-6)THEN             !0001B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                               !0001E
                    IF(AKZ1.GT.-16.)THEN             !0002B
                        IF(AKR.LT.99.7)THEN            !0003B
                            IF(AKZ1.LT.-1.E-2)THEN
                                KJ1=INT(8*(ALOG10(-AKZ1)+4.5))
                            ELSE
                                KJ1=INT(5*(ALOG10(-AKZ1)+6))
                            ENDIF
                            KJ1=MAX(KJ1,2)
                            KJ1=MIN(KJ1,TABULATION_JZ-1)
                            IF(AKR.LT.1.)THEN
                                KI=INT(5*(ALOG10(AKR+1.E-20)+6)+1)
                            ELSE
                                KI=INT(3*AKR+28)
                            ENDIF
                            KI=MAX(KI,2)
                            KI=MIN(KI,TABULATION_IR-1)
                            XL1=PL2(XR(KI),XR(KI+1),XR(KI-1),AKR)
                            XL2=PL2(XR(KI+1),XR(KI-1),XR(KI),AKR)
                            XL3=PL2(XR(KI-1),XR(KI),XR(KI+1),AKR)
                            ZL11=PL2(XZ(KJ1),XZ(KJ1+1),XZ(KJ1-1),AKZ1)
                            ZL21=PL2(XZ(KJ1+1),XZ(KJ1-1),XZ(KJ1),AKZ1)
                            ZL31=PL2(XZ(KJ1-1),XZ(KJ1),XZ(KJ1+1),AKZ1)
                            F1=XL1*APD1Z(KI-1,KJ1-1)+XL2*APD1Z(KI,KJ1-1)+ &
                                & XL3*APD1Z(KI+1,KJ1-1)
                            F2=XL1*APD1Z(KI-1,KJ1)+XL2*APD1Z(KI,KJ1)+ &
                                & XL3*APD1Z(KI+1,KJ1)
                            F3=XL1*APD1Z(KI-1,KJ1+1)+XL2*APD1Z(KI,KJ1+1)+ &
                                & XL3*APD1Z(KI+1,KJ1+1)
                            PD1Z1=ZL11*F1+ZL21*F2+ZL31*F3
                            F1=XL1*APD2Z(KI-1,KJ1-1)+XL2*APD2Z(KI,KJ1-1)+ &
                                & XL3*APD2Z(KI+1,KJ1-1)
                            F2=XL1*APD2Z(KI-1,KJ1)+XL2*APD2Z(KI,KJ1)+ &
                                & XL3*APD2Z(KI+1,KJ1)
                            F3=XL1*APD2Z(KI-1,KJ1+1)+XL2*APD2Z(KI,KJ1+1)+ &
                                & XL3*APD2Z(KI+1,KJ1+1)
                            PD2Z1=ZL11*F1+ZL21*F2+ZL31*F3
                        ELSE                           !0003E
                            EPZ1=EXP(AKZ1)
                            AKP4=AKR-PI4
                            SQ=SQRT(DPI/AKR)
                            CSK=COS(AKP4)
                            SIK=SIN(AKP4)
                            PSK=PI*SQ*SIK
                            SCK=SQ*CSK
                            PD1Z1=PSURR1*AKZ1-PSK*EPZ1
                            PD2Z1=EPZ1*SCK
                        ENDIF                         !0003F
                        VZ11=PD1Z1-PSURR1*AKZ1
                        VZ21=PD2Z1
                    ELSE                            !0002E
                        PD1Z1=PSURR1*AKZ1
                        PD2Z1=0.
                        VZ11=0.
                        VZ21=0.
                    ENDIF                           !0002F
                ENDIF                             !0001F
                ZZZ2=ZG(J)-ZMIII-2*H
                AKZ2=AM0*ZZZ2
                DD2=SQRT(RRR**2+ZZZ2**2)
                IF(DD2.GT.EPS)THEN
                    RR2=AM0*DD2
                    PSR2=PI/RR2
                    PSURR2=PI/RR2**3
                ELSE
                    PSR2=0.
                    PSURR2=0.
                ENDIF

                IF(AKZ2.GT.-1.5E-6)THEN            !0004B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                               !0004E
                    IF(AKZ2.GT.-16.)THEN             !0005B
                        IF(AKR.LT.99.7)THEN            !0006B
                            IF(AKZ2.LT.-1.E-2)THEN
                                KJ2=INT(8*(ALOG10(-AKZ2)+4.5))
                            ELSE
                                KJ2=INT(5*(ALOG10(-AKZ2)+6))
                            ENDIF
                            KJ2=MAX(KJ2,2)
                            KJ2=MIN(KJ2,45)
                            ZL12=PL2(XZ(KJ2),XZ(KJ2+1),XZ(KJ2-1),AKZ2)
                            ZL22=PL2(XZ(KJ2+1),XZ(KJ2-1),XZ(KJ2),AKZ2)
                            ZL32=PL2(XZ(KJ2-1),XZ(KJ2),XZ(KJ2+1),AKZ2)
                            F1=XL1*APD1Z(KI-1,KJ2-1)+XL2*APD1Z(KI,KJ2-1)+ &
                                & XL3*APD1Z(KI+1,KJ2-1)
                            F2=XL1*APD1Z(KI-1,KJ2)+XL2*APD1Z(KI,KJ2)+XL3*APD1Z(KI+1,KJ2)
                            F3=XL1*APD1Z(KI-1,KJ2+1)+XL2*APD1Z(KI,KJ2+1)+ &
                                & XL3*APD1Z(KI+1,KJ2+1)
                            PD1Z2=ZL12*F1+ZL22*F2+ZL32*F3
                            F1=XL1*APD2Z(KI-1,KJ2-1)+XL2*APD2Z(KI,KJ2-1)+ &
                                & XL3*APD2Z(KI+1,KJ2-1)
                            F2=XL1*APD2Z(KI-1,KJ2)+XL2*APD2Z(KI,KJ2)+XL3*APD2Z(KI+1,KJ2)
                            F3=XL1*APD2Z(KI-1,KJ2+1)+XL2*APD2Z(KI,KJ2+1)+ &
                                & XL3*APD2Z(KI+1,KJ2+1)
                            PD2Z2=ZL12*F1+ZL22*F2+ZL32*F3
                        ELSE                          !0006E
                            EPZ2=EXP(AKZ2)
                            PD1Z2=PSURR2*AKZ2-PSK*EPZ2
                            PD2Z2=EPZ2*SCK
                        ENDIF                         !0006F
                        VZ12=PD1Z2-PSURR2*AKZ2
                        VZ22=PD2Z2
                    ELSE                            !0005E
                        PD1Z2=PSURR2*AKZ2
                        PD2Z2=0.
                        VZ12=0.
                        VZ22=0.
                    ENDIF                            !0005F
                ENDIF                              !0004F
                ZZZ3=ZMIII-ZG(J)-2*H
                AKZ3=AM0*ZZZ3
                DD3=SQRT(RRR**2+ZZZ3**2)
                IF(DD3.GT.EPS)THEN
                    RR3=AM0*DD3
                    PSR3=PI/RR3
                    PSURR3=PI/RR3**3
                ELSE
                    PSR3=0.
                    PSURR3=0.
                ENDIF

                IF(AKZ3.GT.-1.5E-6)THEN   !0007B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                    !0007E
                    IF(AKZ3.GT.-16.)THEN    !0008B
                        IF(AKR.LT.99.7)THEN     !0009B
                            IF(AKZ3.LT.-1.E-2)THEN
                                KJ3=INT(8*(ALOG10(-AKZ3)+4.5))
                            ELSE
                                KJ3=INT(5*(ALOG10(-AKZ3)+6))
                            ENDIF
                            KJ3=MAX(KJ3,2)
                            KJ3=MIN(KJ3,45)
                            ZL13=PL2(XZ(KJ3),XZ(KJ3+1),XZ(KJ3-1),AKZ3)
                            ZL23=PL2(XZ(KJ3+1),XZ(KJ3-1),XZ(KJ3),AKZ3)
                            ZL33=PL2(XZ(KJ3-1),XZ(KJ3),XZ(KJ3+1),AKZ3)
                            F1=XL1*APD1Z(KI-1,KJ3-1)+XL2*APD1Z(KI,KJ3-1)+ &
                                & XL3*APD1Z(KI+1,KJ3-1)
                            F2=XL1*APD1Z(KI-1,KJ3)+XL2*APD1Z(KI,KJ3)+XL3*APD1Z(KI+1,KJ3)
                            F3=XL1*APD1Z(KI-1,KJ3+1)+XL2*APD1Z(KI,KJ3+1)+ &
                                & XL3*APD1Z(KI+1,KJ3+1)
                            PD1Z3=ZL13*F1+ZL23*F2+ZL33*F3
                            F1=XL1*APD2Z(KI-1,KJ3-1)+XL2*APD2Z(KI,KJ3-1)+ &
                                & XL3*APD2Z(KI+1,KJ3-1)
                            F2=XL1*APD2Z(KI-1,KJ3)+XL2*APD2Z(KI,KJ3)+XL3*APD2Z(KI+1,KJ3)
                            F3=XL1*APD2Z(KI-1,KJ3+1)+XL2*APD2Z(KI,KJ3+1)+ &
                                & XL3*APD2Z(KI+1,KJ3+1)
                            PD2Z3=ZL13*F1+ZL23*F2+ZL33*F3
                        ELSE                    !0009E
                            EPZ3=EXP(AKZ3)
                            PD1Z3=PSURR3*AKZ3-PSK*EPZ3
                            PD2Z3=EPZ3*SCK
                        ENDIF                   !0009F
                        VZ13=PD1Z3-PSURR3*AKZ3
                        VZ23=PD2Z3
                    ELSE                    !0008E
                        PD1Z3=PSURR3*AKZ3
                        PD2Z3=0.
                        VZ13=0.
                        VZ23=0.
                    ENDIF                    !0008F
                ENDIF                    !0007F
                ZZZ4=-ZG(J)-ZMIII-4*H
                AKZ4=AM0*ZZZ4
                DD4=SQRT(RRR**2+ZZZ4**2)
                IF(DD4.GT.EPS)THEN
                    RR4=AM0*DD4
                    PSR4=PI/RR4
                    PSURR4=PI/RR4**3
                ELSE
                    PSR4=0.
                    PSURR4=0.
                ENDIF

                IF(AKZ4.GT.-1.5E-6)THEN       !0010B
                    IF(IJUMP.NE.1)THEN
                        WRITE(*,*)'AKZ < -1.5 E-6'
                        IJUMP=1
                    ENDIF
                ELSE                         !0010E
                    IF(AKZ4.GT.-16.)THEN       !0011B
                        IF(AKR.LT.99.7)THEN      !0012B
                            IF(AKZ4.LT.-1.E-2)THEN
                                KJ4=INT(8*(ALOG10(-AKZ4)+4.5))
                            ELSE
                                KJ4=INT(5*(ALOG10(-AKZ4)+6))
                            ENDIF
                            KJ4=MAX(KJ4,2)
                            KJ4=MIN(KJ4,45)
                            ZL14=PL2(XZ(KJ4),XZ(KJ4+1),XZ(KJ4-1),AKZ4)
                            ZL24=PL2(XZ(KJ4+1),XZ(KJ4-1),XZ(KJ4),AKZ4)
                            ZL34=PL2(XZ(KJ4-1),XZ(KJ4),XZ(KJ4+1),AKZ4)
                            F1=XL1*APD1Z(KI-1,KJ4-1)+XL2*APD1Z(KI,KJ4-1)+ &
                                & XL3*APD1Z(KI+1,KJ4-1)
                            F2=XL1*APD1Z(KI-1,KJ4)+XL2*APD1Z(KI,KJ4)+XL3*APD1Z(KI+1,KJ4)
                            F3=XL1*APD1Z(KI-1,KJ4+1)+XL2*APD1Z(KI,KJ4+1)+ &
                                & XL3*APD1Z(KI+1,KJ4+1)
                            PD1Z4=ZL14*F1+ZL24*F2+ZL34*F3
                            F1=XL1*APD2Z(KI-1,KJ4-1)+XL2*APD2Z(KI,KJ4-1)+ &
                                & XL3*APD2Z(KI+1,KJ4-1)
                            F2=XL1*APD2Z(KI-1,KJ4)+XL2*APD2Z(KI,KJ4)+XL3*APD2Z(KI+1,KJ4)
                            F3=XL1*APD2Z(KI-1,KJ4+1)+XL2*APD2Z(KI,KJ4+1)+ &
                                & XL3*APD2Z(KI+1,KJ4+1)
                            PD2Z4=ZL14*F1+ZL24*F2+ZL34*F3
                        ELSE                     !0012E
                            EPZ4=EXP(AKZ4)
                            PD1Z4=PSURR4*AKZ4-PSK*EPZ4
                            PD2Z4=EPZ4*SCK
                        ENDIF                    !0012F
                        VZ14=PD1Z4-PSURR4*AKZ4
                        VZ24=PD2Z4
                    ELSE                       !0011E
                        PD1Z4=PSURR4*AKZ4
                        PD2Z4=0.
                        VZ14=0.
                        VZ24=0.
                    ENDIF                      !0011F
                ENDIF                      !0010F
                QTQQ=PD1Z1+PD1Z2+PD1Z3+PD1Z4
                FS1(J,JJ)=COF1*(QTQQ-PSR1-PSR2-PSR3-PSR4)
                STSS=PD2Z1+PD2Z2+PD2Z3+PD2Z4
                FS2(J,JJ)=COF2*STSS
                                
                IF(I.LE.IMX)THEN   !501 B
                    IF(RRR.GT.EPS)THEN !601B
                        IF(AKZ1.LE.-1.5E-6)THEN !701B
                            IF(AKZ1.GT.-16.)THEN  !801B
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ1-1)+XL2*APD1X(KI,KJ1-1)+ &
                                        & XL3*APD1X(KI+1,KJ1-1)
                                    F2=XL1*APD1X(KI-1,KJ1)+XL2*APD1X(KI,KJ1)+ &
                                        & XL3*APD1X(KI+1,KJ1)
                                    F3=XL1*APD1X(KI-1,KJ1+1)+XL2*APD1X(KI,KJ1+1)+ &
                                        & XL3*APD1X(KI+1,KJ1+1)
                                    PD1X1=ZL11*F1+ZL21*F2+ZL31*F3
                                    F1=XL1*APD2X(KI-1,KJ1-1)+XL2*APD2X(KI,KJ1-1)+ &
                                        & XL3*APD2X(KI+1,KJ1-1)
                                    F2=XL1*APD2X(KI-1,KJ1)+XL2*APD2X(KI,KJ1)+XL3*APD2X(KI+1,KJ1)
                                    F3=XL1*APD2X(KI-1,KJ1+1)+XL2*APD2X(KI,KJ1+1)+ &
                                        & XL3*APD2X(KI+1,KJ1+1)
                                    PD2X1=ZL11*F1+ZL21*F2+ZL31*F3
                                ELSE
                                    DSK=0.5/AKR
                                    SCDS=PI*SQ*(CSK-DSK*SIK)
                                    SSDS=SQ*(SIK+DSK*CSK)
                                    PD1X1=-PSURR1*AKR-EPZ1*SCDS
                                    PD2X1=EPZ1*SSDS
                                ENDIF
                                VR21=-PD2X1
                            ELSE !801E
                                PD1X1=-PSURR1*AKR
                                PD2X1=0.
                                VR21=0.
                            ENDIF   !801F
                        ENDIF !701F
                        IF(AKZ2.LE.-1.5E-6)THEN
                            IF(AKZ2.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ2-1)+XL2*APD1X(KI,KJ2-1)+ &
                                        & XL3*APD1X(KI+1,KJ2-1)
                                    F2=XL1*APD1X(KI-1,KJ2)+XL2*APD1X(KI,KJ2)+ &
                                        & XL3*APD1X(KI+1,KJ2)
                                    F3=XL1*APD1X(KI-1,KJ2+1)+XL2*APD1X(KI,KJ2+1)+ &
                                        &XL3*APD1X(KI+1,KJ2+1)
                                    PD1X2=ZL12*F1+ZL22*F2+ZL32*F3
                                    F1=XL1*APD2X(KI-1,KJ2-1)+XL2*APD2X(KI,KJ2-1)+ &
                                        & XL3*APD2X(KI+1,KJ2-1)
                                    F2=XL1*APD2X(KI-1,KJ2)+XL2*APD2X(KI,KJ2)+ &
                                        & XL3*APD2X(KI+1,KJ2)
                                    F3=XL1*APD2X(KI-1,KJ2+1)+XL2*APD2X(KI,KJ2+1)+ &
                                        & XL3*APD2X(KI+1,KJ2+1)
                                    PD2X2=ZL12*F1+ZL22*F2+ZL32*F3
                                ELSE
                                    PD1X2=-PSURR2*AKR-EPZ2*SCDS
                                    PD2X2=EPZ2*SSDS
                                ENDIF
                                VR22=-PD2X2
                            ELSE
                                PD1X2=-PSURR2*AKR
                                PD2X2=0.
                                VR22=0.
                            ENDIF
                        ENDIF
                        IF(AKZ3.LE.-1.5E-6)THEN
                            IF(AKZ3.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ3-1)+XL2*APD1X(KI,KJ3-1)+ &
                                        & XL3*APD1X(KI+1,KJ3-1)
                                    F2=XL1*APD1X(KI-1,KJ3)+XL2*APD1X(KI,KJ3)+ &
                                        & XL3*APD1X(KI+1,KJ3)
                                    F3=XL1*APD1X(KI-1,KJ3+1)+XL2*APD1X(KI,KJ3+1)+ &
                                        & XL3*APD1X(KI+1,KJ3+1)
                                    PD1X3=ZL13*F1+ZL23*F2+ZL33*F3
                                    F1=XL1*APD2X(KI-1,KJ3-1)+XL2*APD2X(KI,KJ3-1)+ &
                                        & XL3*APD2X(KI+1,KJ3-1)
                                    F2=XL1*APD2X(KI-1,KJ3)+XL2*APD2X(KI,KJ3)+ &
                                        & XL3*APD2X(KI+1,KJ3)
                                    F3=XL1*APD2X(KI-1,KJ3+1)+XL2*APD2X(KI,KJ3+1)+ &
                                        & XL3*APD2X(KI+1,KJ3+1)
                                    PD2X3=ZL13*F1+ZL23*F2+ZL33*F3
                                ELSE
                                    PD1X3=-PSURR3*AKR-EPZ3*SCDS
                                    PD2X3=EPZ3*SSDS
                                ENDIF
                                VR23=-PD2X3
                            ELSE
                                PD1X3=-PSURR3*AKR
                                PD2X3=0.
                                VR23=0.
                            ENDIF
                        ENDIF
                        IF(AKZ4.LE.-1.5E-6)THEN
                            IF(AKZ4.GT.-16.)THEN
                                IF(AKR.LT.99.7)THEN
                                    F1=XL1*APD1X(KI-1,KJ4-1)+XL2*APD1X(KI,KJ4-1)+ &
                                        & XL3*APD1X(KI+1,KJ4-1)
                                    F2=XL1*APD1X(KI-1,KJ4)+XL2*APD1X(KI,KJ4)+ &
                                        & XL3*APD1X(KI+1,KJ4)
                                    F3=XL1*APD1X(KI-1,KJ4+1)+XL2*APD1X(KI,KJ4+1)+ &
                                        & XL3*APD1X(KI+1,KJ4+1)
                                    PD1X4=ZL14*F1+ZL24*F2+ZL34*F3
                                    F1=XL1*APD2X(KI-1,KJ4-1)+XL2*APD2X(KI,KJ4-1)+ &
                                        & XL3*APD2X(KI+1,KJ4-1)
                                    F2=XL1*APD2X(KI-1,KJ4)+XL2*APD2X(KI,KJ4)+ &
                                        & XL3*APD2X(KI+1,KJ4)
                                    F3=XL1*APD2X(KI-1,KJ4+1)+XL2*APD2X(KI,KJ4+1)+ &
                                        & XL3*APD2X(KI+1,KJ4+1)
                                    PD2X4=ZL14*F1+ZL24*F2+ZL34*F3
                                ELSE
                                    PD1X4=-PSURR4*AKR-EPZ4*SCDS
                                    PD2X4=EPZ4*SSDS
                                ENDIF
                                VR24=-PD2X4
                            ELSE
                                PD1X4=-PSURR4*AKR
                                PD2X4=0.
                                VR24=0.
                            ENDIF
                        ENDIF
                        C1V3=-COF3*(PD1X1+PD1X2+PD1X3+PD1X4)
                        C2V3=COF4*(VR21+VR22+VR23+VR24)
                        CVX=(XGI-XG(J))/RRR
                        CVY=(YGI-YMJJJ)/RRR
                        VSX1(J,JJ)=C1V3*CVX
                        VSX2(J,JJ)=C2V3*CVX
                        VSY1(J,JJ)=C1V3*CVY
                        VSY2(J,JJ)=C2V3*CVY
                    ELSE                                 !601E
                        VSX1(J,JJ)=0.
                        VSX2(J,JJ)=0.
                        VSY1(J,JJ)=0.
                        VSY2(J,JJ)=0.
                    ENDIF                                 !601F
                    VSZ1(J,JJ)=COF3*(PD1Z1-PD1Z2+PD1Z3-PD1Z4)
                    VSZ2(J,JJ)=COF4*(VZ21-VZ22+VZ23-VZ24)
                ENDIF                                   !501F
    
                XPG=XGI-XG(J)
                YPG=YGI-YMJJJ
                ACT=-0.5*AIRE(J)/QPI
                DO KE=1,NEXP1
                    AQT=ACT*SolverVar%AR(KE)
                    ZPG1=ZMIII-2.*H+H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG2=-ZMIII-H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG3=-ZMIII-4.*H+H*SolverVar%AMBDA(KE)-ZG(J)
                    ZPG4=ZMIII+2.*H-H*SolverVar%AMBDA(KE)-ZG(J)
                    RR1=RRR**2+ZPG1**2
                    RO1=SQRT(RR1)
                    IF(RO1.GT.EPS)THEN
                        FTS1=AQT/RO1
                        ASRO1=FTS1/RR1
                    ELSE
                        FTS1=0.
                        ASRO1=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS1=-XPG*ASRO1
                        VYS1=-YPG*ASRO1
                        VZS1=-ZPG1*ASRO1
                    ENDIF
                    RR2=RRR**2+ZPG2**2
                    RO2=SQRT(RR2)
                    IF(RO2.GT.EPS)THEN
                        FTS2=AQT/RO2
                        ASRO2=FTS2/RR2
                    ELSE
                        FTS2=0.
                        ASRO2=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS2=-XPG*ASRO2
                        VYS2=-YPG*ASRO2
                        VZS2=-ZPG2*ASRO2
                    ENDIF
                    RR3=RRR**2+ZPG3**2
                    RO3=SQRT(RR3)
                    IF(RO3.GT.EPS)THEN
                        FTS3=AQT/RO3
                        ASRO3=FTS3/RR3
                    ELSE
                        FTS3=0.
                        ASRO3=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS3=-XPG*ASRO3
                        VYS3=-YPG*ASRO3
                        VZS3=-ZPG3*ASRO3
                    ENDIF
                    RR4=RRR**2+ZPG4**2
                    RO4=SQRT(RR4)
                    IF(RO4.GT.EPS)THEN
                        FTS4=AQT/RO4
                        ASRO4=FTS4/RR4
                    ELSE
                        FTS4=0.
                        ASRO4=0.
                    ENDIF
                    IF(I.LE.IMX)THEN
                        VXS4=-XPG*ASRO4
                        VYS4=-YPG*ASRO4
                        VZS4=-ZPG4*ASRO4
                    ENDIF
                    FS1(J,JJ)=FS1(J,JJ)+FTS1+FTS2+FTS3+FTS4
                    IF(I.LE.IMX)THEN
                        VSX1(J,JJ)=VSX1(J,JJ)+(VXS1+VXS2+VXS3+VXS4)
                        VSY1(J,JJ)=VSY1(J,JJ)+(VYS1+VYS2+VYS3+VYS4)
                        VSZ1(J,JJ)=VSZ1(J,JJ)+(VZS1-VZS2-VZS3+VZS4)
                    ENDIF
                END DO
            ELSE !0000E

                FS1(J,JJ)=0.
                FS2(J,JJ)=0.
                VSX1(J,JJ)=0.
                VSX2(J,JJ)=0.
                VSY1(J,JJ)=0.
                VSY2(J,JJ)=0.
                VSZ1(J,JJ)=0.
                VSZ2(J,JJ)=0.
                KK(1)=M1(J)
                KK(2)=M2(J)
                KK(3)=M3(J)
                KK(4)=M4(J)
                KK(5)=KK(1)
                DO IT=1,SolverVar%NQ
                    TETA=SolverVar%QQ(IT)
                    CT=COS(TETA)
                    ST=SIN(TETA)
                    DO L=1,4
                        OM=(XGI-X(KK(L)))*CT+(YGI-BX*Y(KK(L)))*ST
                        ZIJ(1,L)=AM0*(Z(KK(L))+ZMIII+ZI*OM)
                        ZIJ(2,L)=AM0*(Z(KK(L))-ZMIII-2*H+ZI*OM)
                        ZIJ(3,L)=AM0*(ZMIII-Z(KK(L))-2*H+ZI*OM)
                        ZIJ(4,L)=AM0*(-Z(KK(L))-ZMIII-4*H+ZI*OM)
                        DO KL=1,4
                            IF(REAL(ZIJ(KL,L)).GT.-25.)THEN
                                CEX(KL,L)=CEXP(ZIJ(KL,L))
                            ELSE
                                CEX(KL,L)=(0.,0.)
                            ENDIF
                            GZ(KL,L)=GG(ZIJ(KL,L),CEX(KL,L))
                            CL(KL,L)=CLOG(-ZIJ(KL,L))
                        END DO
                    END DO
                    DO KL=1,4
                        ZIJ(KL,5)=ZIJ(KL,1)
                        CEX(KL,5)=CEX(KL,1)
                        GZ(KL,5)=GZ(KL,1)
                        CL(KL,5)=CL(KL,1)
                    END DO
                    S1=(0.,0.)
                    S2=(0.,0.)
                    ZV1=(0.,0.)
                    ZV2=(0.,0.)
                    ZV3=(0.,0.)
                    ZV4=(0.,0.)
                    ZIRS=ZI*ZN(J)*ST
                    ZIRC=ZI*ZN(J)*CT
                    DO L=1,4
                        DXL=(X(KK(L+1))-X(KK(L)))
                        DYL=(Y(KK(L+1))-Y(KK(L)))*BX
                        DO KL=1,4
                            BKL=(-1)**(KL+1)
                            IF(KL.LT.3)THEN
                                AUX=DXL*(YN(J)*BX-ZIRS)-DYL*(XN(J)-ZIRC)
                            ELSE
                                AUX=DXL*(-YN(J)*BX-ZIRS)-DYL*(-XN(J)-ZIRC)
                            ENDIF
                            Z1=ZIJ(KL,L+1)
                            Z0=ZIJ(KL,L)
                            CL1=CL(KL,L+1)
                            CL0=CL(KL,L)
                            G1=GZ(KL,L+1)
                            G0=GZ(KL,L)
                            CEX1=CEX(KL,L+1)
                            CEX0=CEX(KL,L)
                            ZAM=Z1-Z0
                            IF(ABS(AIMAG(ZAM)).LT.EPS.AND.ABS(REAL(ZAM)).LT.EPS)THEN
                                S1=S1+AUX*(G1+G0+CL1+CL0)*0.5
                                ZV1=ZV1+AUX*BKL*(G1+G0)*0.5
                                ZV3=ZV3+AUX*(G1+G0)*0.5
                                S2=S2+AUX*(CEX1+CEX0)*0.5
                                ZV2=ZV2+AUX*BKL*(CEX1+CEX0)*0.5
                                ZV4=ZV4+AUX*(CEX1+CEX0)*0.5
                            ELSE
                                S1=S1+AUX*(G1-G0+CL1-CL0+Z1*CL1-Z0*CL0-ZAM)/ZAM
                                ZV1=ZV1+AUX*BKL*(G1-G0+CL1-CL0)/ZAM
                                ZV3=ZV3+AUX*(G1-G0+CL1-CL0)/ZAM
                                S2=S2+AUX*(CEX1-CEX0)/ZAM
                                ZV2=ZV2+AUX*BKL*(CEX1-CEX0)/ZAM
                                ZV4=ZV4+AUX*(CEX1-CEX0)/ZAM
                            ENDIF
                        END DO
                    END DO
                    FS1(J,JJ)=FS1(J,JJ)+SolverVar%CQ(IT)*REAL(S1)*COE1*BX
                    FS2(J,JJ)=FS2(J,JJ)+SolverVar%CQ(IT)*REAL(S2)*COE2*BX
                    VSX1(J,JJ)=VSX1(J,JJ)-SolverVar%CQ(IT)*CT*AIMAG(ZV3)*COE3*BX
                    VSX2(J,JJ)=VSX2(J,JJ)-SolverVar%CQ(IT)*CT*AIMAG(ZV4)*COE4*BX
                    VSY1(J,JJ)=VSY1(J,JJ)-SolverVar%CQ(IT)*ST*AIMAG(ZV3)*COE3*BX
                    VSY2(J,JJ)=VSY2(J,JJ)-SolverVar%CQ(IT)*ST*AIMAG(ZV4)*COE4*BX
                    VSZ1(J,JJ)=VSZ1(J,JJ)+SolverVar%CQ(IT)*REAL(ZV1)*COE3*BX
                    VSZ2(J,JJ)=VSZ2(J,JJ)+SolverVar%CQ(IT)*REAL(ZV2)*COE4*BX
                END DO
                ZP(1)=-ZMIII
                ZP(2)=ZMIII+2*H
                ZP(3)=ZMIII-2.*H
                ZP(4)=-ZMIII-4*H
                DO L=1,5
                    XFT(L)=X(KK(L))
                    YFT(L)=Y(KK(L))
                    ZFT(L)=Z(KK(L))
                END DO
                DO KE=1,NEXP1
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(1)-H*SolverVar%AMBDA(KE),FFS1,VX1,VY1,VZ1)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(2)-H*SolverVar%AMBDA(KE),FFS2,VX2,VY2,VZ2)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(3)+H*SolverVar%AMBDA(KE),FFS3,VX3,VY3,VZ3)
                    CALL VSD(XFT,YFT,ZFT,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),XG(J),&
                        & YG(J),ZG(J),XGI,YGI,ZP(4)+H*SolverVar%AMBDA(KE),FFS4,VX4,VY4,VZ4)
                    FS1(J,JJ)=FS1(J,JJ)+(FFS1+FFS2+FFS3+FFS4)*SolverVar%AR(KE)
                    IF(I.LE.IMX)THEN
                        VSX1(J,JJ)=VSX1(J,JJ)+(VX1+VX2+VX3+VX4)*SolverVar%AR(KE)
                        VSY1(J,JJ)=VSY1(J,JJ)+(VY1+VY2+VY3+VY4)*SolverVar%AR(KE)
                        VSZ1(J,JJ)=VSZ1(J,JJ)+(-VZ1+VZ2+VZ3-VZ4)*SolverVar%AR(KE)
                    ENDIF
                END DO

            ENDIF !0000F
        END DO

        IF(NSYMY.EQ.1)THEN  !101B
        
            SolverVar%SM1=SolverVar%FSM+FS1(J,1)-FS1(J,2)
            SolverVar%SP1=SolverVar%FSP+FS1(J,1)+FS1(J,2)
            SolverVar%SM2=FS2(J,1)-FS2(J,2)
            SolverVar%SP2=FS2(J,1)+FS2(J,2)
            SolverVar%VSXP1=SolverVar%VSXP+VSX1(J,1)+VSX1(J,2)
            SolverVar%VSXM1=SolverVar%VSXM+VSX1(J,1)-VSX1(J,2)
            SolverVar%VSYP1=SolverVar%VSYP+VSY1(J,1)+VSY1(J,2)
            SolverVar%VSYM1=SolverVar%VSYM+VSY1(J,1)-VSY1(J,2)
            SolverVar%VSZP1=SolverVar%VSZP+VSZ1(J,1)+VSZ1(J,2)
            SolverVar%VSZM1=SolverVar%VSZM+VSZ1(J,1)-VSZ1(J,2)
            SolverVar%VSXP2=VSX2(J,1)+VSX2(J,2)
            SolverVar%VSXM2=VSX2(J,1)-VSX2(J,2)
            SolverVar%VSYP2=VSY2(J,1)+VSY2(J,2)
            SolverVar%VSYM2=VSY2(J,1)-VSY2(J,2)
            SolverVar%VSZP2=VSZ2(J,1)+VSZ2(J,2)
            SolverVar%VSZM2=VSZ2(J,1)-VSZ2(J,2)
        ELSE      !101E
            SolverVar%SP1=SolverVar%FSP+FS1(J,1)
            SolverVar%SM1=SolverVar%SP1
            SolverVar%SP2=FS2(J,1)
            SolverVar%SM2=SolverVar%SP2
            SolverVar%VSXP1=SolverVar%VSXP+VSX1(J,1)
            SolverVar%VSXM1=SolverVar%VSXP1
            SolverVar%VSYP1=SolverVar%VSYP+VSY1(J,1)
            SolverVar%VSYM1=SolverVar%VSYP1
            SolverVar%VSZP1=SolverVar%VSZP+VSZ1(J,1)
            SolverVar%VSZM1=SolverVar%VSZP1
            SolverVar%VSXP2=VSX2(J,1)
            SolverVar%VSXM2=SolverVar%VSXP2
            SolverVar%VSYP2=VSY2(J,1)
            SolverVar%VSYM2=SolverVar%VSYP2
            SolverVar%VSZP2=VSZ2(J,1)
            SolverVar%VSZM2=SolverVar%VSZP2

            ! It is assumed VVV has been run with deriv == 2 also
            IF(deriv == 2) THEN

                SolverVar%VSXP1=SolverVar%VSXP - VSX1(J,1)
                SolverVar%VSXM1=SolverVar%VSXP1

                SolverVar%VSYP1=SolverVar%VSYP-VSY1(J,1)
                SolverVar%VSYM1=SolverVar%VSYP1

                SolverVar%VSZP1=SolverVar%VSZP - VSZ1(J,1)
                SolverVar%VSZM1=SolverVar%VSZP1

                SolverVar%VSXP2=-VSX2(J,1)
                SolverVar%VSXM2=SolverVar%VSXP2

                SolverVar%VSYP2 = -VSY2(J,1)
                SolverVar%VSYM2=SolverVar%VSYP2

                SolverVar%VSZP2 = -VSZ2(J,1)
                SolverVar%VSZM2=SolverVar%VSZP2

            END IF
        ENDIF !101F

        RETURN
    END SUBROUTINE
    !------------------------------------------------------------------------

    SUBROUTINE CINT_FD(AKK,N)

        INTEGER::I,J,N,NPIN
        REAL::AKK,CQ(101),QQ(101),PI
        REAL:: Q8(8),CQ8(8),Q12(12),CQ12(12),Q16(16),CQ16(16)
        REAL:: Q24(24),CQ24(24),Q32(32),CQ32(32)

        ! Note that these variables does not really changes
        ! There are just symmetric. You could put them in COM_VAR to save space
        Q8 = (/.4801449,.3983332,.2627662,.09171732,(0., I=1,4)/)
        CQ8 = (/.05061427,.1111905,.1568533,.1813419,(0., I=1,4)/)
        Q12 = (/.4907803,.4520586,.3849513,.2936589,.1839157,.06261670,&
            & (0., I=1,6)/)
        CQ12 = (/.2358766E-1,.5346966E-1,.8003916E-1,.1015837,&
            &.1167462,.1245735,(0., I=1,6)/)
        Q16 = (/.4947004,.4722875,.4328156,.3777022,.3089381,.2290084,&
            &.1408017,.04750625,(0., I=1,8)/)
        CQ16 = (/.01357622,.03112676,.04757925,.06231448,.07479799,&
            &.08457826,.09130170,.09472530,(0., I=1,8)/)
        Q24 = (/.4975936,.4873642,.469137,.4432077,.4100009,.3700621,&
            &.3240468,.2727107,.2168967,.1575213,.09555943,.032028446,(0., I=1,12)/)
        CQ24 = (/.6170615E-2,.1426569E-1,.2213872E-1,.2964929E-1,&
            &.366732E-1,.4309508E-1,.4880932E-1,.5372213E-1,.5775283E-1,&
            &.6083523E-1,.6291873E-1,.6396909E-1,(0., I=1,12)/)
        Q32 = (/.4986319,.4928057,.4823811,.4674530,.4481605,.4246838,&
            &.3972418,.3660910,.3315221,.2938578,.2534499,.2106756,.1659343,&
            &.1196436,.07223598,.02415383,(0., I=1,16)/)
        CQ32 = (/.350930E-2,.8137197E-2,.1269603E-1,.1713693E-1,&
            & .2141794E-1,.2549903E-1,.2934204E-1,.3291111E-1,&
            & .3617289E-1,.3909694E-1,.4165596E-1,.4382604E-1,&
            & .4558693E-1,.4692219E-1,.4781936E-1,.4827004E-1,(0., I=1,16)/)

        NPIN=101
        PI=4.*ATAN(1.)

        IF(AKK-.4 <= 0) THEN
            N=8
            DO I=1,4
                Q8(I)=Q8(I)
                Q8(9-I)=-Q8(I)
                CQ8(I)=CQ8(I)
                CQ8(9-I)=CQ8(I)
            END DO
            DO J=1,N
                QQ(J)=Q8(J)*PI
                CQ(J)=CQ8(J)*PI
            END DO
            RETURN

        ELSE IF(AKK-2.5 <= 0) THEN

            N=12
            DO I=1,6
                Q12(I)=Q12(I)
                Q12(13-I)=-Q12(I)
                CQ12(I)=CQ12(I)
                CQ12(13-I)=CQ12(I)
            END DO
            DO J=1,N
                QQ(J)=Q12(J)*PI
                CQ(J)=CQ12(J)*PI
            END DO
            RETURN

        ELSE IF(AKK-4. <= 0) THEN
            N=16
            DO I=1,8
                Q16(I)=Q16(I)
                Q16(17-I)=-Q16(I)
                CQ16(I)=CQ16(I)
                CQ16(17-I)=CQ16(I)
            END DO
            DO J=1,N
                QQ(J)=Q16(J)*PI
                CQ(J)=CQ16(J)*PI
            END DO
            RETURN

        ELSE IF(AKK-8. <= 0) THEN

            N=24
            DO I=1,12
                Q24(I)=Q24(I)
                Q24(25-I)=-Q24(I)
                CQ24(I)=CQ24(I)
                CQ24(25-I)=CQ24(I)
            END DO
            DO J=1,N
                QQ(J)=Q24(J)*PI
                CQ(J)=CQ24(J)*PI
            END DO
            RETURN

        ELSE IF(AKK-25. <= 0) THEN

            N=32
            DO I=1,16
                Q32(I)=Q32(I)
                Q32(33-I)=-Q32(I)
                CQ32(I)=CQ32(I)
                CQ32(33-I)=CQ32(I)
            END DO
            DO J=1,N
                QQ(J)=Q32(J)*PI
                CQ(J)=CQ32(J)*PI
            END DO

            RETURN

        END IF

        N=51
        IF(AKK >  40.)THEN
            N=NPIN
        END IF

        DO J=1,N
            QQ(J)=-PI/2.+(J-1.)/(N-1.)*PI
            IF(J-1 <= 0 .or. J-N >=0) THEN
                CQ(J)=PI/(3.*(N-1.))
                CYCLE
            END IF

            IF(MOD(J,2) /= 0) THEN
                CQ(J)=2./(3.*(N-1.))*PI
                CYCLE
            END IF

            CQ(J)=4./(3.*(N-1.))*PI

        END DO
    END SUBROUTINE
    !--------------------------------------------------------------------------
                                                                  
    SUBROUTINE LISC(AK0,AM0,NM,SolverVar)
                                     
        INTEGER::NM,I,J,NJ,NPP
        REAL:: AK0,AM0
        REAL:: POL(31),A,B,H
        REAL:: S(4*(31-1),31+1),XT(4*(31-1)+1),YT(4*(31-1)+1)
        REAL:: SC(31),VR(31),VC(31)
        INTEGER::ISTIR,NMAX,NK,ISOR,NPI,NMO,NEXR
        REAL:: PRECI,ERMAX,ERMOY,XX,YY,TT,DIF,RT
        COMPLEX:: COM(31)
        TYPE(TempVar) :: SolverVar

        S=0.
        SC=0.
        SolverVar%AR=0.
        NEXR=31
        PRECI=1.E-02
        ISTIR=0
        NMAX=4*(NEXR-1)
        NK=4
        A=-0.1
        B=20.
        DO
            NM=NK
            NJ=4*NM
            NPP=NJ+1
            H=(B-A)/NJ
            DO I=1,NPP
                XT(I)=A+(I-1)*H
                YT(I)=FF(XT(I),AK0,AM0)
            END DO
            ISOR=0
            CALL EXPORS(XT,YT,NJ,NM,SolverVar%AMBDA,NMAX,S,SC,VR,VC,COM,POL,SolverVar%AR)

            NPI=2
            NMO=NPI*NPP-NPI+1
            ERMAX=0.
            ERMOY=0.
            DO I=1,NMO
                XX=(I-1)*B/(NMO-1)
                YY=FF(XX,AK0,AM0)
                TT=0.
                DO J=1,NM
                    RT=SolverVar%AMBDA(J)*XX
                    IF(RT.GT.-20.)THEN
                        TT=TT+SolverVar%AR(J)*EXP(RT)
                    ENDIF
                END DO
                DIF=YY-TT
                ERMOY=ERMOY+DIF
                ERMAX=AMAX1(ERMAX,ABS(DIF))
                IF(ABS(DIF).GT.PRECI)ISOR=1
            END DO
            ERMOY=ERMOY/NMO

            IF(ISTIR /= 1 .and. ISOR /= 0) THEN
                NK=NK+2
                IF(NK-(NEXR-1) <= 0) THEN
                    CYCLE
                END IF
            END IF
    
            EXIT

        END DO

        DO J=1,NM
            IF(SolverVar%AMBDA(J).GT.0.)STOP
        END DO

    END SUBROUTINE
    !-------------------------------------------------------------------------------!

    SUBROUTINE EXPORS(XT,YT,NJ,NM,VCOM,NMAX,S,SC,VR,VC,COM,POL,AR)
        INTEGER::NJ,NM,NMAX
        REAL:: VCOM(31),POL(31),AR(31),SC(31),VR(31),VC(31)
        REAL:: S(4*(31-1),31+1),XT(4*(31-1)+1),YT(4*(31-1)+1)
        COMPLEX:: COM(31)
        INTEGER::I,J,K,NPP,JJ,II,IJ,MN,NEXP
        INTEGER::IS,IER
        REAL::H,EPS
                                                     
        NPP=NJ+1
        H=(XT(NPP)-XT(1))/NJ
        K=NPP-NM
        DO I=1,K
            DO J=1,NM
                JJ=NM-J+I
                S(I,J)=YT(JJ)
            END DO
            II=NM+I
            S(I,NM+1)=-YT(II)
        END DO
        EPS=1.E-20
                                                                
        CALL HOUSRS(S,NMAX,K,NM,1,EPS)
        DO I=1,NM
            IJ=NM-I+1
            SC(IJ)=S(I,NM+1)
        END DO
        MN=NM+1
        SC(MN)=1.
        CALL SPRBM(SC,MN,VR,VC,POL,IS,IER)
        DO I=1,NM
            COM(I)=CMPLX(VR(I),VC(I))
            COM(I)=CLOG(COM(I))/H
            VR(I)=REAL(COM(I))
            VC(I)=AIMAG(COM(I))
        END DO
        I=1
        J=0
        DO
            IF(VC(I) == 0) THEN

                J=J+1
                VCOM(J)=VR(I)
                I=I+1

            ELSE IF(ABS(VR(I)-VR(I+1))-1.E-5 <= 0) THEN
                J=J+1
                VCOM(J)=VR(I)
                I=I+2

            ELSE

                J=J+1
                VCOM(J)=VR(I)
                I=I+1

            END IF

            IF(I-NM > 0)  THEN
                EXIT
            END IF
        END DO

        NEXP=J
        J=0

        DO I=1,NEXP
            J=J+1
            IF(VCOM(I) < 0. .and. VCOM(I)+20. > 0) THEN
                VCOM(J)=VCOM(I)
            ELSE
                J=J-1
            ENDIF

        END DO

        NEXP=J
        NM=NEXP
        CALL MCAS(NEXP,VCOM,XT,YT,NPP,AR,S,NMAX)
    END SUBROUTINE
    !----------------------------------------------------------------------------

    SUBROUTINE MCAS(NEXP,TEXP,XT,YT,NPP,AR,A,NMAX)
        INTEGER:: NEXP,NPP,NMAX
        REAL::XT(4*(31-1)+1),YT(4*(31-1)+1),A(4*(31-1),31+1),AR(31),TEXP(31)
        INTEGER::I,J,L,M,N
        REAL::S,TT,TTT,EPS
                        
        EPS=1.E-20
        DO I=1,NEXP
            DO J=1,NEXP
                S=0
                DO L=1,NPP
                    TT=(TEXP(I)+TEXP(J))*XT(L)
                    IF(TT+30 >= 0) THEN
                        S=S+EXP(TT)
                    END IF

                END DO
                A(I,J)=S
            END DO
        END DO
        DO I=1,NEXP
            S=0
            DO L=1,NPP
                TTT=TEXP(I)*XT(L)
                IF(TTT+30 >= 0) THEN
                    S=S+EXP(TTT)*YT(L)
                END IF
            END DO
            A(I,NEXP+1)=S
        END DO
        N=NEXP
        M=N+1
        CALL HOUSRS(A,NMAX,N,N,1,EPS)
        DO I=1,NEXP
            AR(I)=A(I,NEXP+1)
        END DO
        RETURN
                                                                    
    END SUBROUTINE
    !----------------------------------------------------------------------

    SUBROUTINE SPRBM(C,IC,RR,RC,POL,IR,IER)
        INTEGER::IC,IR,IER
        REAL:: C(31),RR(31),RC(31),POL(31)
        INTEGER::I,J,L,N,LIM,IST
        REAL::A,B,H
        REAL::EPS,Q1,Q2,Q(4)
        LOGICAL :: terminate_subroutine, exit_outer_loop
        CHARACTER(LEN=*), PARAMETER  :: FMT = "(/5X,'IER = ',I3,'  ERREUR DANS SPRBM'/)"

        EPS=1.E-6
        LIM=100
        IR=IC+1
        DO
            IR=IR-1
            IF(IR-1 <= 0) THEN
                IER = 2
                IR = 0
                WRITE(*,FMT)IER
                STOP
            END IF

            IF(C(IR) /= 0) THEN
                EXIT
            END IF
        END DO

        IER=0
        J=IR
        L=0
        A=C(IR)


        DO I=1,IR
            IF(L <= 0) THEN
                IF(C(I) == 0) THEN
                    RR(I)=0.
                    RC(I)=0.
                    POL(J)=0.
                    J=J-1
                    CYCLE
                ELSE
                    L=1
                    IST=I
                    J=0
                END IF

            END IF

            J=J+1
            C(I)=C(I)/A
            POL(J)=C(I)
            IF(ABS(POL(J))-1.E27 >= 0) THEN
                IER = 2
                IR = 0
                WRITE(*,FMT)IER
                STOP
            END IF

        END DO

        Q1=0.
        Q2=0.

        DO

            IF(J-2 == 0) THEN

                A=POL(1)
                RR(IST)=-A
                RC(IST)=0.
                IR=IR-1
                Q2=0.

                IF(IR-1 > 0) THEN

                    DO I=2,IR
                        Q1=Q2
                        Q2=POL(I+1)
                        POL(I)=A*Q2+Q1
                    END DO
                END IF

                POL(IR+1)=A+Q2
                EXIT

            ELSE IF(J-2 > 0) THEN

                DO L=1,10
                    N=1
                    DO
                        Q(1)=Q1
                        Q(2)=Q2
                        CALL SPQFB(POL,J,Q,LIM,I)
                        IF(I == 0) THEN
                            terminate_subroutine = .false.
                            exit_outer_loop = .true.
                            EXIT

                        ELSE IF(I > 0) THEN
                            IER=1
                            terminate_subroutine = .false.
                            exit_outer_loop = .true.
                            EXIT
                        END IF

                        IF(Q1 == 0 .and. Q2 == 0) THEN
                            Q1=1.+Q1
                            Q2=1.-Q2
                            exit_outer_loop = .false.
                            EXIT

                        ELSE IF( N == 4) THEN

                            Q1=1.+Q1
                            Q2=1.-Q2
                            exit_outer_loop = .false.
                            EXIT

                        ELSE IF(N == 2) THEN

                            Q2=-Q2
                            N=N+1

                        ELSE

                            Q1=-Q1
                            N=N+1


                        END IF
                    END DO

                    IF(exit_outer_loop) THEN
                        EXIT
                    END IF
                    terminate_subroutine = .true.
                END DO

                IF(terminate_subroutine) THEN
                    IER=3
                    IR=IR-J
                    RETURN
                END IF

                Q1=Q(1)
                Q2=Q(2)
                B=0.
                A=0.
                I=J
                DO

                    H=-Q1*B-Q2*A+POL(I)
                    POL(I)=B
                    B=A
                    A=H
                    I=I-1

                    IF(I-2 <= 0) THEN
                        EXIT
                    END IF

                END DO

                POL(2)=B
                POL(1)=A
                L=IR-1

                IF(J-L <= 0)  THEN
                    DO I=J,L
                        POL(I-1)=POL(I-1)+POL(I)*Q2+POL(I+1)*Q1
                    END DO
                END IF

                POL(L)=POL(L)+POL(L+1)*Q2+Q1
                POL(IR)=POL(IR)+Q2
                H=-.5*Q2
                A=H*H-Q1
                B=SQRT(ABS(A))

                IF(A <= 0) THEN

                    RR(IST)=H
                    RC(IST)=B
                    IST=IST+1
                    RR(IST)=H
                    RC(IST)=-B

                ELSE

                    B=H+SIGN(B,H)
                    RR(IST)=Q1/B
                    RC(IST)=0.
                    IST=IST+1
                    RR(IST)=B
                    RC(IST)=0.

                END IF

                IST=IST+1
                J=J-2



            ELSE

                IR=IR-1
                EXIT
            END IF

        END DO

        A=0.
        DO I=1,IR
            Q1=C(I)
            Q2=POL(I+1)
            POL(I)=Q2

            IF(Q1 /= 0) THEN
                Q2=(Q1-Q2)/Q1
            END IF

            Q2=ABS(Q2)

            IF(Q2-A > 0) THEN
                A=Q2
            END IF

        END DO

        I=IR+1
        POL(I)=1.
        RR(I)=A
        RC(I)=0.

        IF(IER <=0 .and. A-EPS > 0) THEN
            IER=-1
        END IF

        IF(IER-2 == 0) THEN
            WRITE(*,FMT)IER
            STOP
        END IF
                                                                  
    END SUBROUTINE
    !----------------------------------------------------------------

    SUBROUTINE SPQFB(C,IC,Q,LIM,IER)
        INTEGER::IC,LIM,IER,I,J,L,LL
        REAL:: C(31),Q(4)
        REAL:: H,HH,A,A1,AA,B,BB,B1,C1,CA,CB,CC,CD,DQ1,DQ2,EPS,EPS1
        REAL:: Q1,Q2,QQ1,QQ2,QQQ1,QQQ2
      
        !--------- Value non initialized in previous versions ?!
        H=0.
        HH=0.
        !---------
        IER=0
        J = IC

        DO

            IF(J- 1 <= 0) THEN
                IER = -1
                RETURN
            END IF

            IF(C(J) /= 0)   THEN
                EXIT
            END IF

        END DO

        A = C(J)

        IF(A-1 /= 0) THEN

            DO I=1,J
                C(I)=C(I)/A
                IF(ABS(C(I))-1.E27 >= 0) THEN
                    IER = -1
                    RETURN
                END IF

            END DO

        END IF

        IF(J-3 < 0) THEN

            IER=-2
            RETURN

        ELSE IF(J-3  ==  0) THEN

            Q(1)=C(1)
            Q(2)=C(2)
            Q(3)=0.
            Q(4)=0.
            RETURN
        END IF

        DO
            EPS=1.E-14
            EPS1=1.E-6
            L=0
            LL=0
            Q1=Q(1)
            Q2=Q(2)
            QQ1=0.
            QQ2=0.
            AA=C(1)
            BB=C(2)
            CB=ABS(AA)
            CA=ABS(BB)

            IF(CB-CA < 0) THEN
                CC=CB+CB
                CB=CB/CA
                CA=1.
            ELSE IF(CB-CA == 0) THEN

                CC=CA+CA
                CA=1.
                CB=1.

            ELSE

                CC=CA+CA
                CA=CA/CB
                CB=1.

            END IF


            CD=CC*.1

            DO

                A=0.
                B=A
                A1=A
                B1=A
                I=J
                QQQ1=Q1
                QQQ2=Q2
                DQ1=HH
                DQ2=H

                DO
                    H=-Q1*B-Q2*A+C(I)
                    ! If H is too big or too small, this is an error and we stop the subroutine execution
                    IF((ABS(H)-1.E27) >= 0)  THEN
                        IER=-3
                        Q(1)=QQ1
                        Q(2)=QQ2
                        Q(3)=AA
                        Q(4)=BB
                        RETURN
                    END IF



                    B=A
                    A=H
                    I=I-1

                    IF(I-1 < 0) THEN
                        EXIT
                    ELSE IF(I-1 == 0) THEN
                        H = 0
                    END IF

                    H=-Q1*B1-Q2*A1+H

                    IF((ABS(H)-1.E27) >= 0)  THEN
                        IER=-3
                        Q(1)=QQ1
                        Q(2)=QQ2
                        Q(3)=AA
                        Q(4)=BB
                        RETURN
                    END IF

                    C1=B1
                    B1=A1
                    A1=H


                END DO

                H=CA*ABS(A)+CB*ABS(B)

                IF(LL > 0) THEN
                    Q(1)=Q1
                    Q(2)=Q2
                    Q(3)=A
                    Q(4)=B
                    RETURN
                END IF

                L = L + 1
                IF((ABS(A)-EPS*ABS(C(1))) <= 0 .and. (ABS(B)-EPS*ABS(C(2))) <= 0) THEN

                    Q(1)=Q1
                    Q(2)=Q2
                    Q(3)=A
                    Q(4)=B
                    RETURN

                END IF

                IF(H-CC <=  0) THEN
                    AA=A
                    BB=B
                    CC=H
                    QQ1=Q1
                    QQ2=Q2
                END IF

                IF(L-LIM > 0) THEN

                    IF(H-CD <= 0) THEN

                        IER=1
                        Q(1)=QQ1
                        Q(2)=QQ2
                        Q(3)=AA
                        Q(4)=BB

                        RETURN


                    END IF

                    IF(Q(1) == 0 .and. Q(2) == 0) THEN
                        IER=-3
                        Q(1)=QQ1
                        Q(2)=QQ2
                        Q(3)=AA
                        Q(4)=BB
                        RETURN

                    END IF

                    Q(1) = 0;
                    Q(2) = 0;

                    EXIT


                END IF

                HH=AMAX1(ABS(A1),ABS(B1),ABS(C1))

                IF(HH <= 0) THEN
                    IER=-3
                    Q(1)=QQ1
                    Q(2)=QQ2
                    Q(3)=AA
                    Q(4)=BB
                    RETURN


                END IF

                A1=A1/HH
                B1=B1/HH
                C1=C1/HH
                H=A1*C1-B1*B1

                IF(H == 0) THEN

                    IER=-3
                    Q(1)=QQ1
                    Q(2)=QQ2
                    Q(3)=AA
                    Q(4)=BB
                    RETURN

                END IF

                A=A/HH
                B=B/HH
                HH=(B*A1-A*B1)/H
                H=(A*C1-B*B1)/H
                Q1=Q1+HH
                Q2=Q2+H

                IF(ABS(HH)-EPS*ABS(Q1) <= 0 .and. ABS(H)-EPS*ABS(Q2) <= 0) THEN

                    LL=1
                    CYCLE


                END IF

                IF(L-1 <= 0 ) THEN
                    CYCLE
                END IF

                IF(ABS(HH)-EPS1*ABS(Q1) > 0) THEN
                    CYCLE
                END IF

                IF(ABS(H)-EPS1*ABS(Q2) > 0) THEN
                    CYCLE
                END IF

                IF(ABS(QQQ1*HH)-ABS(Q1*DQ1) >= 0) THEN

                    Q(1)=QQ1
                    Q(2)=QQ2
                    Q(3)=AA
                    Q(4)=BB
                    RETURN
                END IF

                IF(ABS(QQQ2*H)-ABS(Q2*DQ2) < 0) THEN
                    CYCLE
                END IF

                Q(1)=QQ1
                Q(2)=QQ2
                Q(3)=AA
                Q(4)=BB
                RETURN







            END DO


        END DO
    END SUBROUTINE
    !---------------------------------------------------------------------

    SUBROUTINE HOUSRS(A,NMAX,NL,NCC,NS,EPS)
        INTEGER::NMAX,NL,NCC,NS
        REAL:: A(NMAX,31+1),EPS
        INTEGER::I,J,K,L,M,NCJ,NTC,KP1
        REAL::E,E0,AR,BA,ETA
        INTEGER :: I1
        CHARACTER(LEN=*), PARAMETER  :: FMT1 = "(' NBRE DE COLONNES > NBRES DE LIGNES')"
        CHARACTER(LEN=*), PARAMETER  :: FMT2 = "(1X,'NORME INFERIEURE A ',1PE16.6/)"

        NTC=NCC+NS
        IF(NCC.GT.NL)THEN
            WRITE(*,FMT1)
            STOP
        ENDIF
        DO K=1,NCC
            E=0
            DO I=K,NL
                E=E+A(I,K)**2
            END DO
            E0=SQRT(E)
            IF(E0.LT.EPS)THEN
                WRITE(*,FMT2)EPS
                STOP
            ENDIF
            IF(A(K,K).EQ.0)THEN
                AR=-E0
            ELSE
                AR=-SIGN(E0,A(K,K))
            ENDIF
            ETA=AR*(AR-A(K,K))
            KP1=K+1
            DO J=KP1,NTC
                BA=(A(K,K)-AR)*A(K,J)
                DO I=KP1,NL
                    BA=BA+A(I,K)*A(I,J)
                END DO
                A(K,J)=A(K,J)+BA/AR
                DO I=KP1,NL
                    A(I,J)=A(I,J)-A(I,K)*BA/ETA
                END DO
            END DO
            A(K,K)=AR
            DO I=KP1,NL
                A(I,K)=0
            END DO
        END DO
        DO J=1,NS
            NCJ=NCC+J
            A(NCC,NCJ)=A(NCC,NCJ)/A(NCC,NCC)
            DO L=2,NCC
                I1=NCC+1-L
                M=I1+1
                DO I=M,NCC
                    A(I1,NCJ)=A(I1,NCJ)-A(I1,I)*A(I,NCJ)
                END DO
                A(I1,NCJ)=A(I1,NCJ)/A(I1,I1)
            END DO
        END DO
        RETURN

    END SUBROUTINE
    !-----------------------------------------------------------

    SUBROUTINE VSD(XFT,YFT,ZFT,JJ,XNF,YNF,ZNF,A,TD,XGJ,YGJ,ZGJ, &
        & XGI,YGI,ZIG,FS,VX,VY,VZ)
        INTEGER::JJ
        REAL::XGJ,YGJ,ZGJ,XGI,YGI,ZIG,FS,VX,VY,VZ
        REAL:: A,TD,XNF,YNF,ZNF,XFT(5),YFT(5),ZFT(5)
        REAL:: QPI
        INTEGER::MJJ,L
        REAL:: RR(5),DRX(5),DRY(5),DRZ(5)
        REAL:: AIJS,ALDEN,ANL,ANLX,ANLY,ANLZ,ANT,ANTY,ANTX,ANTZ,ARG,ASRO
        REAL:: AT,ATX,ATY,ATZ,DAT,DDK,DEN,DENL,DENT,DK,DLG
        REAL::DNL,DNT,DNTX,DNTY,DNTZ,DR,DS,EPS,GY,GYX,GYZ,GYY,GZ,PJ,QJ
        REAL::QMP,RJ,RO,SGN,VXS,VZS,VYS


        QPI=4.*4.*ATAN(1.)
        MJJ=(-1)**(JJ+1)
        QMP=MJJ/(2*QPI)
        EPS=1.E-4
        RO=SQRT((XGI-XGJ)**2+(YGI-YGJ*MJJ)**2+(ZIG-ZGJ)**2)
        GZ=(XGI-XGJ)*XNF+(YGI-YGJ*MJJ)*YNF*MJJ+(ZIG-ZGJ)*ZNF
        IF(RO.GT.7*TD)THEN
            FS=-A/(RO*2*QPI)
            ASRO=FS/RO**2
            VX=-(XGI-XGJ)*ASRO
            VY=-(YGI-YGJ*MJJ)*ASRO
            VZ=-(ZIG-ZGJ)*ASRO
        ELSE
            DO L=1,4
                RR(L)=SQRT((XGI-XFT(L))**2+(YGI-YFT(L)*MJJ)**2+(ZIG-ZFT(L))**2)
                DRX(L)=(XGI-XFT(L))/RR(L)
                DRY(L)=(YGI-YFT(L)*MJJ)/RR(L)
                DRZ(L)=(ZIG-ZFT(L))/RR(L)
            END DO
            RR(5)=RR(1)
            DRX(5)=DRX(1)
            DRY(5)=DRY(1)
            DRZ(5)=DRZ(1)
            AIJS=0.
            VXS=0.
            VYS=0.
            VZS=0.
            DO L=1,4
                DK=SQRT((XFT(L+1)-XFT(L))**2+(YFT(L+1)-YFT(L))**2+(ZFT(L+1)-ZFT(L))**2)
                IF(DK.GE.1.E-3*TD)THEN
                    PJ=(XFT(L+1)-XFT(L))/DK
                    QJ=(YFT(L+1)-YFT(L))*MJJ/DK
                    RJ=(ZFT(L+1)-ZFT(L))/DK
                    GYX=YNF*MJJ*RJ-ZNF*QJ
                    GYY=ZNF*PJ-XNF*RJ
                    GYZ=XNF*QJ-YNF*MJJ*PJ
                    GY=(XGI-XFT(L))*GYX+(YGI-YFT(L)*MJJ)*GYY+(ZIG-ZFT(L))*GYZ
                    SGN=SIGN(1.,GZ)
                    DDK=2.*DK
                    ANT=GY*DDK
                    DNT=(RR(L+1)+RR(L))**2-DK*DK+2.*ABS(GZ)*(RR(L+1)+RR(L))
                    ANL=RR(L+1)+RR(L)+DK
                    DNL=RR(L+1)+RR(L)-DK
                    DEN=ANL/DNL
                    ALDEN=ALOG(DEN)
                    IF(ABS(GZ).GT.1.E-4*TD)THEN
                        ARG=ANT/DNT
                        AT=ATAN(ARG)
                    ELSE
                        AT=0.
                    ENDIF
                    AIJS=AIJS+GY*ALDEN-2.*ABS(GZ)*AT
                    DAT=2.*AT*SGN
                    ANTX=GYX*DDK
                    ANTY=GYY*DDK
                    ANTZ=GYZ*DDK
                    ANLX=DRX(L+1)+DRX(L)
                    ANLY=DRY(L+1)+DRY(L)
                    ANLZ=DRZ(L+1)+DRZ(L)
                    DR=2.*(RR(L+1)+RR(L)+ABS(GZ))
                    DS=2.*(RR(L+1)+RR(L))*SGN
                    DNTX=DR*ANLX+XNF*DS
                    DNTY=DR*ANLY+YNF*MJJ*DS
                    DNTZ=DR*ANLZ+ZNF*DS
                    DENL=ANL*DNL
                    DENT=ANT*ANT+DNT*DNT
                    ATX=(ANTX*DNT-DNTX*ANT)/DENT
                    ATY=(ANTY*DNT-DNTY*ANT)/DENT
                    ATZ=(ANTZ*DNT-DNTZ*ANT)/DENT
                    DLG=(DNL-ANL)/DENL
                    VXS=VXS+GYX*ALDEN+GY*ANLX*DLG-2.*ABS(GZ)*ATX-DAT*XNF
                    VYS=VYS+GYY*ALDEN+GY*ANLY*DLG-2.*ABS(GZ)*ATY-DAT*YNF*MJJ
                    VZS=VZS+GYZ*ALDEN+GY*ANLZ*DLG-2.*ABS(GZ)*ATZ-DAT*ZNF
                ENDIF
            END DO
            FS=-AIJS*QMP
            VX=-VXS*QMP
            VY=-VYS*QMP
            VZ=-VZS*QMP
        ENDIF
        RETURN
    END SUBROUTINE
    !---------------------------------------------------------------------

    FUNCTION FF(XTT,AK,AM)
        REAL::XTT,AK,AM
        REAL::COEF,TOL,H,A,B,C,D,E,F,FF
        COEF=(AM+AK)**2/(AM**2-AK**2+AK)
        H=XTT-AM
        TOL=AMAX1(0.1,0.1*AM)
        IF(ABS(H).GT.TOL)THEN
            FF=(XTT+AK)*EXP(XTT)/(XTT*SINH(XTT)-AK*COSH(XTT))-COEF/(XTT-AM)-2.
        ELSE
            A=AM-TOL
            B=AM
            C=AM+TOL
            D=(A+AK)*EXP(A)/(A*SINH(A)-AK*COSH(A))-COEF/(A-AM)-2
            E=COEF/(AM+AK)*(AM+AK+1)-(COEF/(AM+AK))**2*AM-2
            F=(C+AK)*EXP(C)/(C*SINH(C)-AK*COSH(C))-COEF/(C-AM)-2
            FF=(XTT-B)*(XTT-C)*D/((A-B)*(A-C))+(XTT-C)*(XTT-A)*E/((B-C)*(B-A))+&
                & (XTT-A)*(XTT-B)*F/((C-A)*(C-B))
        ENDIF
        RETURN
                                                                    
    END FUNCTION
    !-----------------------------------------------------------------------------

    REAL FUNCTION X0(AK)
        REAL::AK
        INTEGER::ITOUR,IITER
        REAL::XS,XI,XM,PAS,EPS,VAL1,VAL2
        CHARACTER(LEN=*), PARAMETER  :: FMT = "(2X,'ERREUR DANS LA RECHERCHE DE LA RACINE', &                       
      & /2X,'APPROXIMATION =',I5,'   DICHOTOMIE = ',I5)"        
                                                 
        EPS=5.E-6
        ITOUR=0
        XI=0.
        XS=XI
        PAS=AMAX1(AK,SQRT(AK))
        DO
            XS=XS+PAS
            ITOUR=ITOUR+1
            IF(ITOUR.LE.1000)THEN
                VAL1= AK-XS*TANH(XS)
                VAL2= AK-XI*TANH(XI)
                IF(VAL1*VAL2.GT.0) CYCLE
            ENDIF
            EXIT
        END DO
        IITER=0
        DO
            XM=(XI+XS)*0.5
            IITER=IITER+1
            IF(IITER.GT.1000.OR.ITOUR.GT.1000)THEN
                WRITE(*,FMT)ITOUR,IITER
                STOP
            ELSE
                IF(ABS((XS-XI)/XM).GT.EPS)THEN

                    VAL1= AK-XM*TANH(XM)
                    VAL2= AK-XI*TANH(XI)
                    if(abs(val1*val2) .le. 1.E-12)val1=0.
                    IF(VAL1*VAL2.LT.0)THEN
                        XS=XM
                    ELSE
                        XI=XM
                    ENDIF
                    CYCLE
          
                ELSE
                    X0=XM
                ENDIF
            ENDIF
            EXIT
        END DO

        RETURN
    END FUNCTION
    !-----------------------------------------------------------------------------!

    REAL FUNCTION PL2(U1,U2,U3,XU)
        REAL::U1,U2,U3,XU
        PL2=((XU-U1)*(XU-U2))/((U3-U1)*(U3-U2))
        RETURN
    END FUNCTION
END MODULE
