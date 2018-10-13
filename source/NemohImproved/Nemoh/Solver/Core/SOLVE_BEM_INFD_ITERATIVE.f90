!--------------------------------------------------------------------------------------
!
!Copyright (C) 2014 TopCoder Inc., All Rights Reserved.
!
!--------------------------------------------------------------------------------------

!   This module solves the infinite linear BVP (Boundary Value Problem) for the potential.
!   It used an iterative solver for system of linear equations called GMRES


! Changes in version 1.2 (Code Acceleration of the Calculation of Influence Coefficients of Nemoh)
!       Allow fast code for influence coefficients to be run according to a switch
!
! Changes in version 1.3 (Implementation of Higher Order Panel Methods)
!       Added COMMON_TYPE module as dependency

!   @author yedtoss
!   @version 1.3

MODULE SOLVE_BEM_INFD_ITERATIVE

    USE COMMON_TYPE
    USE COM_VAR
    USE ELEMENTARY_FNS
    USE COMPUTE_GREEN_INFD
    USE M_SOLVER
    USE GMRES
    USE COMPUTE_INFLUENCE_ODE
    IMPLICIT NONE

CONTAINS
    !--------------------------------------------------------------------------!
    SUBROUTINE SOLVE_POTENTIAL_INFD_ITERATIVE(NVEL,SolverVar,TD)
    ! Finalfix modification for the iterative solver

        !In this subroutine the linear system Ax=b is constructed

        COMPLEX,DIMENSION(*) :: NVEL
        INTEGER :: BX,ISYM,NJJ,TD
        INTEGER ::I,J,ISP,IFP
        INTEGER:: NP1,I1,JJ, N
        REAL:: GM, BJ, DIJ, AKK
        REAL:: W,tdepth
        REAL:: PCOS,PSIN
        REAL:: AM0,PI,DPI,ZERO
        COMPLEX:: ZOL(IMX,2)

        integer :: lwork(2)
        integer :: revcom, colx, coly, colz, nbscal
        integer :: irc(5,2), icntl(8), info(3, 2)
        TYPE(GMRESVAR):: gmres_env(2)

        integer :: matvec, precondLeft, precondRight, dotProd
        parameter (matvec=1, precondLeft=2, precondRight=3, dotProd=4)

        complex, dimension(:), allocatable ::  work
        real ::  cntl(5), rinfo(2,2)
        complex :: ONE, ZZERO
        real :: start, finish

        TYPE(TempVar), TARGET :: SolverVar
        REAL, POINTER :: T
        COMPLEX, DIMENSION(:), POINTER :: ZPB,ZPS
        COMPLEX, DIMENSION(:), POINTER :: ZIGB,ZIGS
        COMPLEX, DIMENSION(:, :), POINTER :: ZIJ
        REAL, POINTER :: FSP,FSM,VSXP,VSYP,VSZP,VSXM,VSYM,VSZM
        REAL, POINTER :: SP1,SM1,SP2,SM2
        REAL, POINTER :: VSXP1,VSXP2,VSYP1,VSYP2,VSZP1,VSZP2
        REAL, POINTER :: VSXM1,VSXM2,VSYM1,VSYM2,VSZM1,VSZM2
        INTEGER, POINTER:: NQ
        REAL, POINTER:: CQ(:),QQ(:),AMBDA(:),AR(:)
        T => SolverVar%T
        ZPB => SolverVar%ZPB
        ZPS => SolverVar%ZPS
        ZIGB => SolverVar%ZIGB
        ZIGS => SolverVar%ZIGS
        ZIJ => SolverVar%ZIJ
        FSP => SolverVar%FSP
        FSM => SolverVar%FSM
        VSXP => SolverVar%VSXP
        VSYP => SolverVar%VSYP
        VSZP => SolverVar%VSZP
        VSXM => SolverVar%VSXM
        VSYM => SolverVar%VSYM
        VSZM => SolverVar%VSZM
        SP1 => SolverVar%SP1
        SM1 => SolverVar%SM1
        SP2 => SolverVar%SP2
        SM2 => SolverVar%SM2
        VSXP1 => SolverVar%VSXP1
        VSXP2 => SolverVar%VSXP2
        VSYP1 => SolverVar%VSYP1
        VSYP2 => SolverVar%VSYP2
        VSZP1 => SolverVar%VSZP1
        VSZP2 => SolverVar%VSZP2
        VSXM1 => SolverVar%VSXM1
        VSXM2 => SolverVar%VSXM2
        VSYM1 => SolverVar%VSYM1
        VSYM2 => SolverVar%VSYM2
        VSZM1 => SolverVar%VSZM1
        VSZM2 => SolverVar%VSZM2
        NQ => SolverVar%NQ
        CQ => SolverVar%CQ
        QQ => SolverVar%QQ
        AMBDA => SolverVar%AMBDA
        AR => SolverVar%AR

        lwork = (restartParam+10)**2 + (restartParam+10)*(IMX+5) + 5*IMX + 1
        ALLOCATE(work(lwork(1)))
        ONE = CMPLX(1., 0.)
        ZZERO = CMPLX(0., 0.)

        NJJ=NSYMY+1
        PI=4.*ATAN(1.)
        DPI=2.*PI
        W=DPI/T
        ZERO=0.0
        AM0=W**2/G
        tdepth=1.E+20
        !--------------Initilizations---------------
        CQ=0.0
        QQ=0.0
        VSXP=0.
        VSXM=0.
        VSYP=0.
        VSYM=0.
        VSZP=0.
        VSZM=0.
        ZOL=CMPLX(0.,0.)
        ZIJ=CMPLX(0.,0.)
        !--------------------------------------------
        IF(ProblemSavedAt(SolverVar%ProblemNumber) < 0 ) THEN
            GM=0.
            NP1=NP-1
            DO I=1,NP1
                I1=I+1
                DO JJ=1,NJJ
                    BJ=(-1.)**(JJ+1)
                    DO J=I1,NP
                        DIJ=SQRT((X(J)-X(I))**2+(Y(I)-Y(J)*BJ)**2)
                        GM=MAX(DIJ,GM)
                    END DO
                END DO
            END DO
            AKK=AM0*GM
            CALL CINT_INFD(AKK,N, SolverVar)
            !N=NQ Bug Fixes
            NQ = N
            IF(ProblemSavedAt(SolverVar%ProblemNumber) == -1 ) THEN
                DO I=1,101
                    CQCache(ProblemToSaveLocation(SolverVar%ProblemNumber), I)  = CQ(I)
                    QQCache(ProblemToSaveLocation(SolverVar%ProblemNumber), I) =  QQ(I)
                END DO

            END IF

        ELSE

            DO I=1,101
                CQ(I) = CQCache(ProblemSavedAt(SolverVar%ProblemNumber), I)
                QQ(I) = QQCache(ProblemSavedAt(SolverVar%ProblemNumber), I)
            END DO

        END IF

        !Construction of the influence matrix
        DO ISYM=1,NJJ
            BX=(-1)**(ISYM+1)

            IF(ProblemSavedAt(SolverVar%ProblemNumber) < 0 ) THEN

                IF (SolverVar%Switch_FastInfluence ==1) THEN
                    CALL compute_influence_infinite_dipoles(W, ZIJ) ! Call the subroutine to compute influence
                    !!$OMP CRITICAL
                    !We are safe without a critical or atomic operation. Although we are
                    ! updating it's value, this will be it's final value. And If a thread is still seeing 0 instead
                    ! of 1 after this update, it won't be a issue.  Any thread updating it is doing so with the same
                    ! value
                    is_rankine_dipoles_computed = 1
                    !!$OMP END CRITICAL

                ELSE
!                    call cpu_time(start)

                    call VAVNSINFD(1, 1,ISYM,SolverVar,ZIJ,1,TD)  

!                    call cpu_time(finish)
!                    write(*,*) TD, finish-start, 'INFD'

                END IF

            END IF



            IF(ProblemSavedAt(SolverVar%ProblemNumber) == -1 ) THEN

                    DO J=1,IMX
                DO I=1,IMX

                        InfluenceMatrixCache(I, J, TD, ISYM) = ZIJ(I,J)

                    END DO

                END DO

            END IF


            IF(ProblemSavedAt(SolverVar%ProblemNumber) >= 0 ) THEN

                    DO J=1,IMX
                DO I=1,IMX

                        ZIJ(I,J) = InfluenceMatrixCache(I, J,TD, ISYM)

                    END DO

                END DO

            END IF


            !******************************************************
            !* Initialize the control parameters to default value
            !******************************************************

            call init_cgmres(icntl,cntl,gmres_env(ISYM))

            !************************
            !c Tune some parameters
            !************************

            ! Save the convergence history on standard output
            !icntl(3) = 30
            icntl(2) = 0
            ! Maximum number of iterations
            icntl(7) = maxIterations

            ! Tolerance
            cntl(1) = TOL_GMRES

            ! preconditioner location
            icntl(4) = 0
            ! orthogonalization scheme
            icntl(5)=0
            ! initial guess
            icntl(6) = 0
            ! residual calculation strategy at restart
            icntl(8) = 1
            !* Initialise the right hand side

            work = CMPLX(0., 0.)

            work(1:IMX) = ONE

            DO I=1,IMX
                IF (NSYMY.EQ.1) THEN
                    work(IMX+I)=(NVEL(I)+BX*NVEL(I+NFA))*0.5
                ELSE
                    work(IMX+I)=NVEL(I)
                END IF
            ENDDO

            DO

                call drive_cgmres(IMX,IMX,restartParam,lwork(ISYM),work, &
                    irc(:, ISYM),icntl,cntl,info(:, ISYM),rinfo(:, ISYM), gmres_env(ISYM))
                revcom = irc(1, ISYM)
                colx   = irc(2, ISYM)
                coly   = irc(3, ISYM)
                colz   = irc(4, ISYM)
                nbscal = irc(5, ISYM)

                if (revcom == matvec) then
                    ! perform the matrix vector product
                    !        work(colz) <-- A * work(colx)
                    call cgemv('N',IMX,IMX,ONE,ZIJ,IMX,work(colx),1, &
                        ZZERO,work(colz),1)

                else if (revcom == precondLeft) then
                    ! perform the left preconditioning
                    !         work(colz) <-- M^{-1} * work(colx)
                    call ccopy(IMX,work(colx),1,work(colz),1)
                    call ctrsm('L','L','N','N',IMX,1,ONE,ZIJ,IMX,work(colz),IMX)

                else if (revcom == precondRight) then
                    ! perform the right preconditioning
                    call ccopy(IMX,work(colx),1,work(colz),1)
                    call ctrsm('L','U','N','N',IMX,1,ONE,ZIJ,IMX,work(colz),IMX)

                else if (revcom == dotProd) then
                    !      perform the scalar product
                    !      work(colz) <-- work(colx) work(coly)

                    call cgemv('C',IMX,nbscal,ONE,work(colx),IMX, &
                        work(coly),1,ZZERO,work(colz),1)

                ELSE
                    exit
                endif

            END DO


            DO I=1,IMX
                ZOL(I,(ISYM-1)+1)=work(I)
            END DO

        END DO

        ZIGB=(0.,0.)
        ZIGS=(0.,0.)

        DO I=1,IMX
            IF(NSYMY .EQ. 0)THEN
                ZIGB(I)=ZOL(I,1)    ! Factor 2 is removed in comparison with previous version of Nemoh because
                                    ! Normal velocity is halved in Nemoh (because of symmetry)
                ZIGS(I)=0.0
            ELSE
                ZIGB(I)=(ZOL(I,1)+ZOL(I,2))
                ZIGS(I)=(ZOL(I,1)-ZOL(I,2))
            ENDIF
        END DO

        ZPB=(0.,0.)
        ZPS=(0.,0.)
        !computation of potential phi=S*sigma on the boundary
        IF(ProblemSavedAt(SolverVar%ProblemNumber) < 0 ) THEN
            !N = ProblemToSaveLocation(SolverVar%ProblemNumber)
            IF (SolverVar%Switch_FastInfluence ==1) THEN

                CALL compute_influence_infinite_sources(W, ZIJ) ! Call the subroutine to compute influence
                is_rankine_sources_computed = 1

                DO J=1,IMX
                    DO I=1,IMX
                        ZPS(I)= ZPS(I) -  ZIJ(I, J) * ZIGS(J)
                        ZPB(I)= ZPB(I) -  ZIJ(I, J) * ZIGB(J)
                        IF(ProblemSavedAt(SolverVar%ProblemNumber) == -1 ) THEN
                            SM1Cache(I, J, TD) = REAL(ZIJ(I,J))
                            SM2Cache(I, J, TD) = AIMAG(ZIJ(I,J))
                        END IF
                    END DO
                END DO

            ELSE
!                call cpu_time(start)

                call VAVNSINFD(1, 1,ISYM,SolverVar,ZIJ,2,TD)  

!                call cpu_time(finish)
!                write(*,*) TD, finish-start, 'INFD'

            END IF

        ENDIF

        IF (SolverVar%Switch_FastInfluence ==1) THEN
            DO J=1,IMX
                DO I=1,IMX
                    ZPS(I)= ZPS(I) -  CMPLX(SM1Cache(I, J, TD), SM2Cache(I, J, TD)) * ZIGS(J)
                    ZPB(I)= ZPB(I) -  CMPLX(SM1Cache(I, J, TD), SM2Cache(I, J, TD)) * ZIGB(J)
                END DO
            END DO

        ELSE

            DO J=1,IMX
                DO I=1,IMX

                    ZPB(I)=ZPB(I)+0.5*(ZIGB(J)*CMPLX(SP1Cache(I,J,TD)+SM1Cache(I,J,TD),SP2Cache(I,J,TD)+SM2Cache(I,J,TD))&
                                      +ZIGS(J)*CMPLX(SP1Cache(I,J,TD)-SM1Cache(I,J,TD),SP2Cache(I,J,TD)-SM2Cache(I,J,TD)))
                    ZPS(I)=ZPS(I)+0.5*(ZIGS(J)*CMPLX(SP1Cache(I,J,TD)+SM1Cache(I,J,TD),SP2Cache(I,J,TD)+SM2Cache(I,J,TD))&
                                      +ZIGB(J)*CMPLX(SP1Cache(I,J,TD)-SM1Cache(I,J,TD),SP2Cache(I,J,TD)-SM2Cache(I,J,TD)))
                END DO

            END DO

        END IF


    END SUBROUTINE
!----------------------------------------------------------------------

END MODULE

!*  some control parametrs definition for GMRES
!* icntl    (input) INTEGER array. length 6
!*            icntl(1) : stdout for error messages
!*            icntl(2) : stdout for warnings
!*            icntl(3) : stdout for convergence history
!*            icntl(4) : 0 - no preconditioning
!*                       1 - left preconditioning
!*                       2 - right preconditioning
!*                       3 - double side preconditioning
!*                       4 - error, default set in Init
!*            icntl(5) : 0 - modified Gram-Schmidt
!*                       1 - iterative modified Gram-Schmidt
!*                       2 - classical Gram-Schmidt
!*                       3 - iterative classical Gram-Schmidt
!*            icntl(6) : 0 - default initial guess x_0 = 0 (to be set)
!*                       1 - user supplied initial guess
!*            icntl(7) : maximum number of iterations
!*            icntl(8) : 1 - default compute the true residual at each restart
!*                       0 - use recurence formaula at restart
!*
!* cntl     (input) real array, length 5
!*            cntl(1) : tolerance for convergence
!*            cntl(2) : scaling factor for normwise perturbation on A
!*            cntl(3) : scaling factor for normwise perturbation on b
!*            cntl(4) : scaling factor for normwise perturbation on the
!*                      preconditioned matrix
!*            cntl(5) : scaling factor for normwise perturbation on 
!*                      preconditioned right hand side
