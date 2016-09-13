!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module surfaceintegrations_d
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------

contains
!  differentiation of integratesurfaces in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: *(*bcdata.fv) *(*bcdata.fp)
!                *(*bcdata.area) localvalues
!   with respect to varying inputs: *p *w *x *si *sj *sk *(*viscsubface.tau)
!                *xx *pp1 *pp2 *ssi *ww2 (global)pinf (global)pref
!                (global)veldirfreestream[1:3] (global)machcoef
!                (global)pointref[1:3]
!   plus diff mem management of: viscsubface:in *viscsubface.tau:in
!                bcdata:in *bcdata.fv:in *bcdata.fp:in *bcdata.area:in
!                xx:in-out rev0:out rev1:out rev2:out rev3:out
!                pp0:out pp1:in-out pp2:in-out pp3:out rlv0:out
!                rlv1:out rlv2:out rlv3:out ss:out ssi:in-out ssj:out
!                ssk:out ww0:out ww1:out ww2:in-out ww3:out
  subroutine integratesurfaces_d(localvalues, localvaluesd)
! this is a shell routine that calls the specific surface
! integration routines. currently we have have the forceandmoment
! routine as well as the flow properties routine. this routine
! takes care of setting pointers, while the actual computational
! routine just acts on a specific fast pointed to by pointers. 
    use constants
    use blockpointers, only : nbocos, bcdata, bcdatad, bctype, sk, skd&
&   , sj, sjd, si, sid, x, xd, rlv, rlvd, sfacei, sfaceid, sfacej, &
&   sfacejd, sfacek, sfacekd, gamma, rev, revd, p, pd, viscsubface, &
&   viscsubfaced
    use surfacefamilies, only : famgroups
    use utils_d, only : setbcpointers, setbcpointers_d, resetbcpointers,&
&   iswalltype
    use sorting, only : bsearchintegers
    use costfunctions, only : nlocalvalues
! tapenade like to see these
    use bcpointers_d
    use diffsizes
!  hint: isize1ofdrfbcdata should be the size of dimension 1 of array *bcdata
    implicit none
! do we actually need to zero the forces/area on a wall that wasn't inclded? maybe?
!       ! if it wasn't included, but still a wall...zero
!       if(bctype(mm) == eulerwall .or. &
!            bctype(mm) == nswalladiabatic .or. &
!            bctype(mm) == nswallisothermal) then
!          bcdata(mm)%area = zero
!          bcdata(mm)%fp = zero
!          bcdata(mm)%fv = zero
! input/output variables
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvaluesd
! working variables
    integer(kind=inttype) :: mm
    intrinsic size
    integer :: ii1
    do ii1=1,isize1ofdrfbcdata
      bcdatad(ii1)%fv = 0.0_8
    end do
    do ii1=1,isize1ofdrfbcdata
      bcdatad(ii1)%fp = 0.0_8
    end do
    do ii1=1,isize1ofdrfbcdata
      bcdatad(ii1)%area = 0.0_8
    end do
    localvaluesd = 0.0_8
! loop over all possible boundary conditions
bocos:do mm=1,nbocos
! determine if this boundary condition is to be incldued in the
! currently active group
      if (bsearchintegers(bcdata(mm)%famid, famgroups, size(famgroups)) &
&         .gt. 0) then
! set a bunch of pointers depending on the face id to make
! a generic treatment possible. 
        call setbcpointers_d(mm, .true.)
        if (iswalltype(bctype(mm))) call forcesandmomentsface_d(&
&                                                         localvalues, &
&                                                         localvaluesd, &
&                                                         mm)
! reset the pointers
        call resetbcpointers(mm, .true.)
      end if
    end do bocos
  end subroutine integratesurfaces_d
  subroutine integratesurfaces(localvalues)
! this is a shell routine that calls the specific surface
! integration routines. currently we have have the forceandmoment
! routine as well as the flow properties routine. this routine
! takes care of setting pointers, while the actual computational
! routine just acts on a specific fast pointed to by pointers. 
    use constants
    use blockpointers, only : nbocos, bcdata, bctype, sk, sj, si, x, &
&   rlv, sfacei, sfacej, sfacek, gamma, rev, p, viscsubface
    use surfacefamilies, only : famgroups
    use utils_d, only : setbcpointers, resetbcpointers, iswalltype
    use sorting, only : bsearchintegers
    use costfunctions, only : nlocalvalues
! tapenade like to see these
    use bcpointers_d
    implicit none
! do we actually need to zero the forces/area on a wall that wasn't inclded? maybe?
!       ! if it wasn't included, but still a wall...zero
!       if(bctype(mm) == eulerwall .or. &
!            bctype(mm) == nswalladiabatic .or. &
!            bctype(mm) == nswallisothermal) then
!          bcdata(mm)%area = zero
!          bcdata(mm)%fp = zero
!          bcdata(mm)%fv = zero
! input/output variables
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
! working variables
    integer(kind=inttype) :: mm
    intrinsic size
! loop over all possible boundary conditions
bocos:do mm=1,nbocos
! determine if this boundary condition is to be incldued in the
! currently active group
      if (bsearchintegers(bcdata(mm)%famid, famgroups, size(famgroups)) &
&         .gt. 0) then
! set a bunch of pointers depending on the face id to make
! a generic treatment possible. 
        call setbcpointers(mm, .true.)
        if (iswalltype(bctype(mm))) call forcesandmomentsface(&
&                                                       localvalues, mm)
! reset the pointers
        call resetbcpointers(mm, .true.)
      end if
    end do bocos
  end subroutine integratesurfaces
  subroutine flowpropertiesface(localvalues, mm)
    use constants
    use blockpointers, only : bcfaceid, bcdata, addgridvelocities
    use costfunctions, only : nlocalvalues, imassflow, imassptot, &
&   imassttot, imassps
    use sorting, only : bsearchintegers
    use flowutils_d, only : computeptot, computettot
    use bcpointers_d, only : ssi, sface, ww1, ww2, pp1, pp2
    implicit none
! input/output variables
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    integer(kind=inttype), intent(in) :: mm
! local variables
    real(kind=realtype) :: massflowrate, mass_ptot, mass_ttot, mass_ps
    integer(kind=inttype) :: i, j, ii
    real(kind=realtype) :: fact
    real(kind=realtype) :: sf, vnm, vxm, vym, vzm
    real(kind=realtype) :: pm, ptot, ttot, rhom, massflowratelocal, tmp
    intrinsic mod
    massflowrate = zero
    mass_ptot = zero
    mass_ttot = zero
    mass_ps = zero
    select case  (bcfaceid(mm)) 
    case (imin, jmin, kmin) 
      fact = -one
    case (imax, jmax, kmax) 
      fact = one
    end select
! loop over the quadrilateral faces of the subface. note that
! the nodal range of bcdata must be used and not the cell
! range, because the latter may include the halo's in i and
! j-direction. the offset +1 is there, because inbeg and jnbeg
! refer to nodal ranges and not to cell ranges. the loop
! (without the ad stuff) would look like:
!
! do j=(bcdata(mm)%jnbeg+1),bcdata(mm)%jnend
!    do i=(bcdata(mm)%inbeg+1),bcdata(mm)%inend
    do ii=0,(bcdata(mm)%jnend-bcdata(mm)%jnbeg)*(bcdata(mm)%inend-bcdata&
&       (mm)%inbeg)-1
      i = mod(ii, bcdata(mm)%inend - bcdata(mm)%inbeg) + bcdata(mm)%&
&       inbeg + 1
      j = ii/(bcdata(mm)%inend-bcdata(mm)%inbeg) + bcdata(mm)%jnbeg + 1
      if (addgridvelocities) then
        sf = sface(i, j)
      else
        sf = zero
      end if
      vxm = half*(ww1(i, j, ivx)+ww2(i, j, ivx))
      vym = half*(ww1(i, j, ivy)+ww2(i, j, ivy))
      vzm = half*(ww1(i, j, ivz)+ww2(i, j, ivz))
      rhom = half*(ww1(i, j, irho)+ww2(i, j, irho))
      pm = half*(pp1(i, j)+pp2(i, j))
      vnm = vxm*ssi(i, j, 1) + vym*ssi(i, j, 2) + vzm*ssi(i, j, 3) - sf
      massflowratelocal = rhom*vnm*fact
      massflowrate = massflowrate + massflowratelocal
      call computeptot(rhom, vxm, vym, vzm, pm, ptot)
      call computettot(rhom, vxm, vym, vzm, pm, ttot)
      mass_ptot = mass_ptot + ptot*massflowratelocal
      mass_ttot = mass_ttot + ttot*massflowratelocal
      mass_ps = mass_ps + pm*massflowratelocal
    end do
! increment the local values array with what we computed here
    localvalues(imassflow) = localvalues(imassflow) + massflowrate
    localvalues(imassptot) = localvalues(imassptot) + mass_ptot
    localvalues(imassttot) = localvalues(imassttot) + mass_ttot
    localvalues(imassps) = localvalues(imassps) + mass_ps
  end subroutine flowpropertiesface
!  differentiation of forcesandmomentsface in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: *(*bcdata.fv) *(*bcdata.fp)
!                *(*bcdata.area) localvalues
!   with respect to varying inputs: *(*viscsubface.tau) *(*bcdata.fv)
!                *(*bcdata.fp) *(*bcdata.area) veldirfreestream
!                machcoef pointref pinf pref *xx *pp1 *pp2 *ssi
!                *ww2 localvalues
!   plus diff mem management of: viscsubface:in *viscsubface.tau:in
!                bcdata:in *bcdata.fv:in *bcdata.fp:in *bcdata.area:in
!                xx:in pp1:in pp2:in ssi:in ww2:in
  subroutine forcesandmomentsface_d(localvalues, localvaluesd, mm)
!
!       forcesandmoments computes the contribution of the block
!       given by the pointers in blockpointers to the force and
!       moment of the geometry. a distinction is made
!       between the inviscid and viscous parts. in case the maximum
!       yplus value must be monitored (only possible for rans), this
!       value is also computed. the separation sensor and the cavita-
!       tion sensor is also computed
!       here.
!
    use constants
    use communication
    use blockpointers
!, only : lref, machcoef, pointref
    use flowvarrefstate
    use inputphysics, only : machcoef, machcoefd, pointref, pointrefd,&
&   veldirfreestream, veldirfreestreamd, equations
    use costfunctions, only : nlocalvalues, ifp, ifv, imp, imv, &
&   isepsensor, isepavg, icavitation, sepsensorsharpness, &
&   sepsensoroffset, iyplus
    use sorting, only : bsearchintegers
    use bcpointers_d
    implicit none
! input/output variables
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvaluesd
    integer(kind=inttype) :: mm
! local variables.
    real(kind=realtype), dimension(3) :: fp, fv, mp, mv
    real(kind=realtype), dimension(3) :: fpd, fvd, mpd, mvd
    real(kind=realtype) :: yplusmax, sepsensor, sepsensoravg(3), &
&   cavitation
    real(kind=realtype) :: sepsensord, sepsensoravgd(3), cavitationd
    integer(kind=inttype) :: i, j, ii, blk
    real(kind=realtype) :: pm1, fx, fy, fz, fn, sigma
    real(kind=realtype) :: pm1d, fxd, fyd, fzd
    real(kind=realtype) :: xc, yc, zc, qf(3)
    real(kind=realtype) :: xcd, ycd, zcd
    real(kind=realtype) :: fact, rho, mul, yplus, dwall
    real(kind=realtype) :: v(3), sensor, sensor1, cp, tmp, plocal
    real(kind=realtype) :: vd(3), sensord, sensor1d, cpd, tmpd, plocald
    real(kind=realtype) :: tauxx, tauyy, tauzz
    real(kind=realtype) :: tauxxd, tauyyd, tauzzd
    real(kind=realtype) :: tauxy, tauxz, tauyz
    real(kind=realtype) :: tauxyd, tauxzd, tauyzd
    real(kind=realtype), dimension(3) :: refpoint
    real(kind=realtype), dimension(3) :: refpointd
    real(kind=realtype) :: mx, my, mz, cellarea
    real(kind=realtype) :: mxd, myd, mzd, cellaread
    intrinsic mod
    intrinsic max
    intrinsic sqrt
    intrinsic exp
    real(kind=realtype) :: arg1
    real(kind=realtype) :: arg1d
    real(kind=realtype) :: result1
    real(kind=realtype) :: result1d
    select case  (bcfaceid(mm)) 
    case (imin, jmin, kmin) 
      fact = -one
    case (imax, jmax, kmax) 
      fact = one
    end select
! determine the reference point for the moment computation in
! meters.
    refpointd = 0.0_8
    refpointd(1) = lref*pointrefd(1)
    refpoint(1) = lref*pointref(1)
    refpointd(2) = lref*pointrefd(2)
    refpoint(2) = lref*pointref(2)
    refpointd(3) = lref*pointrefd(3)
    refpoint(3) = lref*pointref(3)
! initialize the force and moment coefficients to 0 as well as
! yplusmax.
    fp = zero
    fv = zero
    mp = zero
    mv = zero
    yplusmax = zero
    sepsensor = zero
    cavitation = zero
    sepsensoravg = zero
    sepsensoravgd = 0.0_8
    vd = 0.0_8
    fpd = 0.0_8
    mpd = 0.0_8
    cavitationd = 0.0_8
    sepsensord = 0.0_8
!
!         integrate the inviscid contribution over the solid walls,
!         either inviscid or viscous. the integration is done with
!         cp. for closed contours this is equal to the integration
!         of p; for open contours this is not the case anymore.
!         question is whether a force for an open contour is
!         meaningful anyway.
!
! loop over the quadrilateral faces of the subface. note that
! the nodal range of bcdata must be used and not the cell
! range, because the latter may include the halo's in i and
! j-direction. the offset +1 is there, because inbeg and jnbeg
! refer to nodal ranges and not to cell ranges. the loop
! (without the ad stuff) would look like:
!
! do j=(bcdata(mm)%jnbeg+1),bcdata(mm)%jnend
!    do i=(bcdata(mm)%inbeg+1),bcdata(mm)%inend
    do ii=0,(bcdata(mm)%jnend-bcdata(mm)%jnbeg)*(bcdata(mm)%inend-bcdata&
&       (mm)%inbeg)-1
      i = mod(ii, bcdata(mm)%inend - bcdata(mm)%inbeg) + bcdata(mm)%&
&       inbeg + 1
      j = ii/(bcdata(mm)%inend-bcdata(mm)%inbeg) + bcdata(mm)%jnbeg + 1
! compute the average pressure minus 1 and the coordinates
! of the centroid of the face relative from from the
! moment reference point. due to the usage of pointers for
! the coordinates, whose original array starts at 0, an
! offset of 1 must be used. the pressure is multipled by
! fact to account for the possibility of an inward or
! outward pointing normal.
      pm1d = fact*((half*(pp2d(i, j)+pp1d(i, j))-pinfd)*pref+(half*(pp2(&
&       i, j)+pp1(i, j))-pinf)*prefd)
      pm1 = fact*(half*(pp2(i, j)+pp1(i, j))-pinf)*pref
      xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i+1, &
&       j+1, 1)) - refpointd(1)
      xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1, &
&       1)) - refpoint(1)
      ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i+1, &
&       j+1, 2)) - refpointd(2)
      yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1, &
&       2)) - refpoint(2)
      zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i+1, &
&       j+1, 3)) - refpointd(3)
      zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1, &
&       3)) - refpoint(3)
      if (bcdata(mm)%iblank(i, j) .lt. 0) then
        blk = 0
      else
        blk = bcdata(mm)%iblank(i, j)
      end if
      fxd = pm1d*ssi(i, j, 1) + pm1*ssid(i, j, 1)
      fx = pm1*ssi(i, j, 1)
      fyd = pm1d*ssi(i, j, 2) + pm1*ssid(i, j, 2)
      fy = pm1*ssi(i, j, 2)
      fzd = pm1d*ssi(i, j, 3) + pm1*ssid(i, j, 3)
      fz = pm1*ssi(i, j, 3)
! iblank forces
      fxd = blk*fxd
      fx = fx*blk
      fyd = blk*fyd
      fy = fy*blk
      fzd = blk*fzd
      fz = fz*blk
! update the inviscid force and moment coefficients.
      fpd(1) = fpd(1) + fxd
      fp(1) = fp(1) + fx
      fpd(2) = fpd(2) + fyd
      fp(2) = fp(2) + fy
      fpd(3) = fpd(3) + fzd
      fp(3) = fp(3) + fz
      mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
      mx = yc*fz - zc*fy
      myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
      my = zc*fx - xc*fz
      mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
      mz = xc*fy - yc*fx
      mpd(1) = mpd(1) + mxd
      mp(1) = mp(1) + mx
      mpd(2) = mpd(2) + myd
      mp(2) = mp(2) + my
      mpd(3) = mpd(3) + mzd
      mp(3) = mp(3) + mz
! save the face-based forces and area
      bcdatad(mm)%fp(i, j, 1) = fxd
      bcdata(mm)%fp(i, j, 1) = fx
      bcdatad(mm)%fp(i, j, 2) = fyd
      bcdata(mm)%fp(i, j, 2) = fy
      bcdatad(mm)%fp(i, j, 3) = fzd
      bcdata(mm)%fp(i, j, 3) = fz
      arg1d = 2*ssi(i, j, 1)*ssid(i, j, 1) + 2*ssi(i, j, 2)*ssid(i, j, 2&
&       ) + 2*ssi(i, j, 3)*ssid(i, j, 3)
      arg1 = ssi(i, j, 1)**2 + ssi(i, j, 2)**2 + ssi(i, j, 3)**2
      if (arg1 .eq. 0.0_8) then
        cellaread = 0.0_8
      else
        cellaread = arg1d/(2.0*sqrt(arg1))
      end if
      cellarea = sqrt(arg1)
      bcdatad(mm)%area(i, j) = cellaread
      bcdata(mm)%area(i, j) = cellarea
! get normalized surface velocity:
      vd(1) = ww2d(i, j, ivx)
      v(1) = ww2(i, j, ivx)
      vd(2) = ww2d(i, j, ivy)
      v(2) = ww2(i, j, ivy)
      vd(3) = ww2d(i, j, ivz)
      v(3) = ww2(i, j, ivz)
      arg1d = 2*v(1)*vd(1) + 2*v(2)*vd(2) + 2*v(3)*vd(3)
      arg1 = v(1)**2 + v(2)**2 + v(3)**2
      if (arg1 .eq. 0.0_8) then
        result1d = 0.0_8
      else
        result1d = arg1d/(2.0*sqrt(arg1))
      end if
      result1 = sqrt(arg1)
      vd = (vd*(result1+1e-16)-v*result1d)/(result1+1e-16)**2
      v = v/(result1+1e-16)
! dot product with free stream
      sensord = -(vd(1)*veldirfreestream(1)+v(1)*veldirfreestreamd(1)+vd&
&       (2)*veldirfreestream(2)+v(2)*veldirfreestreamd(2)+vd(3)*&
&       veldirfreestream(3)+v(3)*veldirfreestreamd(3))
      sensor = -(v(1)*veldirfreestream(1)+v(2)*veldirfreestream(2)+v(3)*&
&       veldirfreestream(3))
!now run through a smooth heaviside function:
      arg1d = -(2*sepsensorsharpness*sensord)
      arg1 = -(2*sepsensorsharpness*(sensor-sepsensoroffset))
      sensord = -(one*arg1d*exp(arg1)/(one+exp(arg1))**2)
      sensor = one/(one+exp(arg1))
! and integrate over the area of this cell and save:
      sensord = sensord*cellarea + sensor*cellaread
      sensor = sensor*cellarea
      sepsensord = sepsensord + sensord
      sepsensor = sepsensor + sensor
! also accumulate into the sepsensoravg
      xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i+1, &
&       j+1, 1))
      xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1, &
&       1))
      ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i+1, &
&       j+1, 2))
      yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1, &
&       2))
      zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i+1, &
&       j+1, 3))
      zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1, &
&       3))
      sepsensoravgd(1) = sepsensoravgd(1) + sensord*xc + sensor*xcd
      sepsensoravg(1) = sepsensoravg(1) + sensor*xc
      sepsensoravgd(2) = sepsensoravgd(2) + sensord*yc + sensor*ycd
      sepsensoravg(2) = sepsensoravg(2) + sensor*yc
      sepsensoravgd(3) = sepsensoravgd(3) + sensord*zc + sensor*zcd
      sepsensoravg(3) = sepsensoravg(3) + sensor*zc
      plocald = pp2d(i, j)
      plocal = pp2(i, j)
      tmpd = -(two*gammainf*(machcoefd*machcoef+machcoef*machcoefd)/(&
&       gammainf*machcoef*machcoef)**2)
      tmp = two/(gammainf*machcoef*machcoef)
      cpd = tmpd*(plocal-pinf) + tmp*(plocald-pinfd)
      cp = tmp*(plocal-pinf)
      sigma = 1.4
      sensor1d = -cpd
      sensor1 = -cp - sigma
      sensor1d = -((-(one*2*10*sensor1d*exp(-(2*10*sensor1))))/(one+exp(&
&       -(2*10*sensor1)))**2)
      sensor1 = one/(one+exp(-(2*10*sensor1)))
      sensor1d = sensor1d*cellarea + sensor1*cellaread
      sensor1 = sensor1*cellarea
      cavitationd = cavitationd + sensor1d
      cavitation = cavitation + sensor1
    end do
!
! integration of the viscous forces.
! only for viscous boundaries.
!
    if (bctype(mm) .eq. nswalladiabatic .or. bctype(mm) .eq. &
&       nswallisothermal) then
! initialize dwall for the laminar case and set the pointer
! for the unit normals.
      dwall = zero
      fvd = 0.0_8
      mvd = 0.0_8
! loop over the quadrilateral faces of the subface and
! compute the viscous contribution to the force and
! moment and update the maximum value of y+.
      do ii=0,(bcdata(mm)%jnend-bcdata(mm)%jnbeg)*(bcdata(mm)%inend-&
&         bcdata(mm)%inbeg)-1
        i = mod(ii, bcdata(mm)%inend - bcdata(mm)%inbeg) + bcdata(mm)%&
&         inbeg + 1
        j = ii/(bcdata(mm)%inend-bcdata(mm)%inbeg) + bcdata(mm)%jnbeg + &
&         1
        if (bcdata(mm)%iblank(i, j) .lt. 0) then
          blk = 0
        else
          blk = bcdata(mm)%iblank(i, j)
        end if
        tauxxd = viscsubfaced(mm)%tau(i, j, 1)
        tauxx = viscsubface(mm)%tau(i, j, 1)
        tauyyd = viscsubfaced(mm)%tau(i, j, 2)
        tauyy = viscsubface(mm)%tau(i, j, 2)
        tauzzd = viscsubfaced(mm)%tau(i, j, 3)
        tauzz = viscsubface(mm)%tau(i, j, 3)
        tauxyd = viscsubfaced(mm)%tau(i, j, 4)
        tauxy = viscsubface(mm)%tau(i, j, 4)
        tauxzd = viscsubfaced(mm)%tau(i, j, 5)
        tauxz = viscsubface(mm)%tau(i, j, 5)
        tauyzd = viscsubfaced(mm)%tau(i, j, 6)
        tauyz = viscsubface(mm)%tau(i, j, 6)
! compute the viscous force on the face. a minus sign
! is now present, due to the definition of this force.
        fxd = -(fact*((tauxxd*ssi(i, j, 1)+tauxx*ssid(i, j, 1)+tauxyd*&
&         ssi(i, j, 2)+tauxy*ssid(i, j, 2)+tauxzd*ssi(i, j, 3)+tauxz*&
&         ssid(i, j, 3))*pref+(tauxx*ssi(i, j, 1)+tauxy*ssi(i, j, 2)+&
&         tauxz*ssi(i, j, 3))*prefd))
        fx = -(fact*(tauxx*ssi(i, j, 1)+tauxy*ssi(i, j, 2)+tauxz*ssi(i, &
&         j, 3))*pref)
        fyd = -(fact*((tauxyd*ssi(i, j, 1)+tauxy*ssid(i, j, 1)+tauyyd*&
&         ssi(i, j, 2)+tauyy*ssid(i, j, 2)+tauyzd*ssi(i, j, 3)+tauyz*&
&         ssid(i, j, 3))*pref+(tauxy*ssi(i, j, 1)+tauyy*ssi(i, j, 2)+&
&         tauyz*ssi(i, j, 3))*prefd))
        fy = -(fact*(tauxy*ssi(i, j, 1)+tauyy*ssi(i, j, 2)+tauyz*ssi(i, &
&         j, 3))*pref)
        fzd = -(fact*((tauxzd*ssi(i, j, 1)+tauxz*ssid(i, j, 1)+tauyzd*&
&         ssi(i, j, 2)+tauyz*ssid(i, j, 2)+tauzzd*ssi(i, j, 3)+tauzz*&
&         ssid(i, j, 3))*pref+(tauxz*ssi(i, j, 1)+tauyz*ssi(i, j, 2)+&
&         tauzz*ssi(i, j, 3))*prefd))
        fz = -(fact*(tauxz*ssi(i, j, 1)+tauyz*ssi(i, j, 2)+tauzz*ssi(i, &
&         j, 3))*pref)
! iblank forces after saving for zipper mesh
        tauxx = tauxx*blk
        tauyy = tauyy*blk
        tauzz = tauzz*blk
        tauxy = tauxy*blk
        tauxz = tauxz*blk
        tauyz = tauyz*blk
        fxd = blk*fxd
        fx = fx*blk
        fyd = blk*fyd
        fy = fy*blk
        fzd = blk*fzd
        fz = fz*blk
! compute the coordinates of the centroid of the face
! relative from the moment reference point. due to the
! usage of pointers for xx and offset of 1 is present,
! because x originally starts at 0.
        xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i+1&
&         , j+1, 1)) - refpointd(1)
        xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1&
&         , 1)) - refpoint(1)
        ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i+1&
&         , j+1, 2)) - refpointd(2)
        yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1&
&         , 2)) - refpoint(2)
        zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i+1&
&         , j+1, 3)) - refpointd(3)
        zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1&
&         , 3)) - refpoint(3)
! update the viscous force and moment coefficients.
        fvd(1) = fvd(1) + fxd
        fv(1) = fv(1) + fx
        fvd(2) = fvd(2) + fyd
        fv(2) = fv(2) + fy
        fvd(3) = fvd(3) + fzd
        fv(3) = fv(3) + fz
        mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
        mx = yc*fz - zc*fy
        myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
        my = zc*fx - xc*fz
        mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
        mz = xc*fy - yc*fx
        mvd(1) = mvd(1) + mxd
        mv(1) = mv(1) + mx
        mvd(2) = mvd(2) + myd
        mv(2) = mv(2) + my
        mvd(3) = mvd(3) + mzd
        mv(3) = mv(3) + mz
! save the face based forces for the slice operations
        bcdatad(mm)%fv(i, j, 1) = fxd
        bcdata(mm)%fv(i, j, 1) = fx
        bcdatad(mm)%fv(i, j, 2) = fyd
        bcdata(mm)%fv(i, j, 2) = fy
        bcdatad(mm)%fv(i, j, 3) = fzd
        bcdata(mm)%fv(i, j, 3) = fz
! compute the tangential component of the stress tensor,
! which is needed to monitor y+. the result is stored
! in fx, fy, fz, although it is not really a force.
! as later on only the magnitude of the tangential
! component is important, there is no need to take the
! sign into account (it should be a minus sign).
        fx = tauxx*bcdata(mm)%norm(i, j, 1) + tauxy*bcdata(mm)%norm(i, j&
&         , 2) + tauxz*bcdata(mm)%norm(i, j, 3)
        fy = tauxy*bcdata(mm)%norm(i, j, 1) + tauyy*bcdata(mm)%norm(i, j&
&         , 2) + tauyz*bcdata(mm)%norm(i, j, 3)
        fz = tauxz*bcdata(mm)%norm(i, j, 1) + tauyz*bcdata(mm)%norm(i, j&
&         , 2) + tauzz*bcdata(mm)%norm(i, j, 3)
        fn = fx*bcdata(mm)%norm(i, j, 1) + fy*bcdata(mm)%norm(i, j, 2) +&
&         fz*bcdata(mm)%norm(i, j, 3)
        fx = fx - fn*bcdata(mm)%norm(i, j, 1)
        fy = fy - fn*bcdata(mm)%norm(i, j, 2)
        fz = fz - fn*bcdata(mm)%norm(i, j, 3)
      end do
    else
! compute the local value of y+. due to the usage
! of pointers there is on offset of -1 in dd2wall..
! if we had no viscous force, set the viscous component to zero
      bcdatad(mm)%fv = 0.0_8
      bcdata(mm)%fv = zero
      fvd = 0.0_8
      mvd = 0.0_8
    end if
! increment the local values array with the values we computed here.
    localvaluesd(ifp:ifp+2) = localvaluesd(ifp:ifp+2) + fpd
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvaluesd(ifv:ifv+2) = localvaluesd(ifv:ifv+2) + fvd
    localvalues(ifv:ifv+2) = localvalues(ifv:ifv+2) + fv
    localvaluesd(imp:imp+2) = localvaluesd(imp:imp+2) + mpd
    localvalues(imp:imp+2) = localvalues(imp:imp+2) + mp
    localvaluesd(imv:imv+2) = localvaluesd(imv:imv+2) + mvd
    localvalues(imv:imv+2) = localvalues(imv:imv+2) + mv
    localvaluesd(isepsensor) = localvaluesd(isepsensor) + sepsensord
    localvalues(isepsensor) = localvalues(isepsensor) + sepsensor
    localvaluesd(icavitation) = localvaluesd(icavitation) + cavitationd
    localvalues(icavitation) = localvalues(icavitation) + cavitation
    localvaluesd(isepavg:isepavg+2) = localvaluesd(isepavg:isepavg+2) + &
&     sepsensoravgd
    localvalues(isepavg:isepavg+2) = localvalues(isepavg:isepavg+2) + &
&     sepsensoravg
  end subroutine forcesandmomentsface_d
  subroutine forcesandmomentsface(localvalues, mm)
!
!       forcesandmoments computes the contribution of the block
!       given by the pointers in blockpointers to the force and
!       moment of the geometry. a distinction is made
!       between the inviscid and viscous parts. in case the maximum
!       yplus value must be monitored (only possible for rans), this
!       value is also computed. the separation sensor and the cavita-
!       tion sensor is also computed
!       here.
!
    use constants
    use communication
    use blockpointers
!, only : lref, machcoef, pointref
    use flowvarrefstate
    use inputphysics, only : machcoef, pointref, veldirfreestream, &
&   equations
    use costfunctions, only : nlocalvalues, ifp, ifv, imp, imv, &
&   isepsensor, isepavg, icavitation, sepsensorsharpness, &
&   sepsensoroffset, iyplus
    use sorting, only : bsearchintegers
    use bcpointers_d
    implicit none
! input/output variables
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    integer(kind=inttype) :: mm
! local variables.
    real(kind=realtype), dimension(3) :: fp, fv, mp, mv
    real(kind=realtype) :: yplusmax, sepsensor, sepsensoravg(3), &
&   cavitation
    integer(kind=inttype) :: i, j, ii, blk
    real(kind=realtype) :: pm1, fx, fy, fz, fn, sigma
    real(kind=realtype) :: xc, yc, zc, qf(3)
    real(kind=realtype) :: fact, rho, mul, yplus, dwall
    real(kind=realtype) :: v(3), sensor, sensor1, cp, tmp, plocal
    real(kind=realtype) :: tauxx, tauyy, tauzz
    real(kind=realtype) :: tauxy, tauxz, tauyz
    real(kind=realtype), dimension(3) :: refpoint
    real(kind=realtype) :: mx, my, mz, cellarea
    intrinsic mod
    intrinsic max
    intrinsic sqrt
    intrinsic exp
    real(kind=realtype) :: arg1
    real(kind=realtype) :: result1
    select case  (bcfaceid(mm)) 
    case (imin, jmin, kmin) 
      fact = -one
    case (imax, jmax, kmax) 
      fact = one
    end select
! determine the reference point for the moment computation in
! meters.
    refpoint(1) = lref*pointref(1)
    refpoint(2) = lref*pointref(2)
    refpoint(3) = lref*pointref(3)
! initialize the force and moment coefficients to 0 as well as
! yplusmax.
    fp = zero
    fv = zero
    mp = zero
    mv = zero
    yplusmax = zero
    sepsensor = zero
    cavitation = zero
    sepsensoravg = zero
!
!         integrate the inviscid contribution over the solid walls,
!         either inviscid or viscous. the integration is done with
!         cp. for closed contours this is equal to the integration
!         of p; for open contours this is not the case anymore.
!         question is whether a force for an open contour is
!         meaningful anyway.
!
! loop over the quadrilateral faces of the subface. note that
! the nodal range of bcdata must be used and not the cell
! range, because the latter may include the halo's in i and
! j-direction. the offset +1 is there, because inbeg and jnbeg
! refer to nodal ranges and not to cell ranges. the loop
! (without the ad stuff) would look like:
!
! do j=(bcdata(mm)%jnbeg+1),bcdata(mm)%jnend
!    do i=(bcdata(mm)%inbeg+1),bcdata(mm)%inend
    do ii=0,(bcdata(mm)%jnend-bcdata(mm)%jnbeg)*(bcdata(mm)%inend-bcdata&
&       (mm)%inbeg)-1
      i = mod(ii, bcdata(mm)%inend - bcdata(mm)%inbeg) + bcdata(mm)%&
&       inbeg + 1
      j = ii/(bcdata(mm)%inend-bcdata(mm)%inbeg) + bcdata(mm)%jnbeg + 1
! compute the average pressure minus 1 and the coordinates
! of the centroid of the face relative from from the
! moment reference point. due to the usage of pointers for
! the coordinates, whose original array starts at 0, an
! offset of 1 must be used. the pressure is multipled by
! fact to account for the possibility of an inward or
! outward pointing normal.
      pm1 = fact*(half*(pp2(i, j)+pp1(i, j))-pinf)*pref
      xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1, &
&       1)) - refpoint(1)
      yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1, &
&       2)) - refpoint(2)
      zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1, &
&       3)) - refpoint(3)
      if (bcdata(mm)%iblank(i, j) .lt. 0) then
        blk = 0
      else
        blk = bcdata(mm)%iblank(i, j)
      end if
      fx = pm1*ssi(i, j, 1)
      fy = pm1*ssi(i, j, 2)
      fz = pm1*ssi(i, j, 3)
! iblank forces
      fx = fx*blk
      fy = fy*blk
      fz = fz*blk
! update the inviscid force and moment coefficients.
      fp(1) = fp(1) + fx
      fp(2) = fp(2) + fy
      fp(3) = fp(3) + fz
      mx = yc*fz - zc*fy
      my = zc*fx - xc*fz
      mz = xc*fy - yc*fx
      mp(1) = mp(1) + mx
      mp(2) = mp(2) + my
      mp(3) = mp(3) + mz
! save the face-based forces and area
      bcdata(mm)%fp(i, j, 1) = fx
      bcdata(mm)%fp(i, j, 2) = fy
      bcdata(mm)%fp(i, j, 3) = fz
      arg1 = ssi(i, j, 1)**2 + ssi(i, j, 2)**2 + ssi(i, j, 3)**2
      cellarea = sqrt(arg1)
      bcdata(mm)%area(i, j) = cellarea
! get normalized surface velocity:
      v(1) = ww2(i, j, ivx)
      v(2) = ww2(i, j, ivy)
      v(3) = ww2(i, j, ivz)
      arg1 = v(1)**2 + v(2)**2 + v(3)**2
      result1 = sqrt(arg1)
      v = v/(result1+1e-16)
! dot product with free stream
      sensor = -(v(1)*veldirfreestream(1)+v(2)*veldirfreestream(2)+v(3)*&
&       veldirfreestream(3))
!now run through a smooth heaviside function:
      arg1 = -(2*sepsensorsharpness*(sensor-sepsensoroffset))
      sensor = one/(one+exp(arg1))
! and integrate over the area of this cell and save:
      sensor = sensor*cellarea
      sepsensor = sepsensor + sensor
! also accumulate into the sepsensoravg
      xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1, &
&       1))
      yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1, &
&       2))
      zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1, &
&       3))
      sepsensoravg(1) = sepsensoravg(1) + sensor*xc
      sepsensoravg(2) = sepsensoravg(2) + sensor*yc
      sepsensoravg(3) = sepsensoravg(3) + sensor*zc
      plocal = pp2(i, j)
      tmp = two/(gammainf*machcoef*machcoef)
      cp = tmp*(plocal-pinf)
      sigma = 1.4
      sensor1 = -cp - sigma
      sensor1 = one/(one+exp(-(2*10*sensor1)))
      sensor1 = sensor1*cellarea
      cavitation = cavitation + sensor1
    end do
!
! integration of the viscous forces.
! only for viscous boundaries.
!
    if (bctype(mm) .eq. nswalladiabatic .or. bctype(mm) .eq. &
&       nswallisothermal) then
! initialize dwall for the laminar case and set the pointer
! for the unit normals.
      dwall = zero
! loop over the quadrilateral faces of the subface and
! compute the viscous contribution to the force and
! moment and update the maximum value of y+.
      do ii=0,(bcdata(mm)%jnend-bcdata(mm)%jnbeg)*(bcdata(mm)%inend-&
&         bcdata(mm)%inbeg)-1
        i = mod(ii, bcdata(mm)%inend - bcdata(mm)%inbeg) + bcdata(mm)%&
&         inbeg + 1
        j = ii/(bcdata(mm)%inend-bcdata(mm)%inbeg) + bcdata(mm)%jnbeg + &
&         1
        if (bcdata(mm)%iblank(i, j) .lt. 0) then
          blk = 0
        else
          blk = bcdata(mm)%iblank(i, j)
        end if
        tauxx = viscsubface(mm)%tau(i, j, 1)
        tauyy = viscsubface(mm)%tau(i, j, 2)
        tauzz = viscsubface(mm)%tau(i, j, 3)
        tauxy = viscsubface(mm)%tau(i, j, 4)
        tauxz = viscsubface(mm)%tau(i, j, 5)
        tauyz = viscsubface(mm)%tau(i, j, 6)
! compute the viscous force on the face. a minus sign
! is now present, due to the definition of this force.
        fx = -(fact*(tauxx*ssi(i, j, 1)+tauxy*ssi(i, j, 2)+tauxz*ssi(i, &
&         j, 3))*pref)
        fy = -(fact*(tauxy*ssi(i, j, 1)+tauyy*ssi(i, j, 2)+tauyz*ssi(i, &
&         j, 3))*pref)
        fz = -(fact*(tauxz*ssi(i, j, 1)+tauyz*ssi(i, j, 2)+tauzz*ssi(i, &
&         j, 3))*pref)
! iblank forces after saving for zipper mesh
        tauxx = tauxx*blk
        tauyy = tauyy*blk
        tauzz = tauzz*blk
        tauxy = tauxy*blk
        tauxz = tauxz*blk
        tauyz = tauyz*blk
        fx = fx*blk
        fy = fy*blk
        fz = fz*blk
! compute the coordinates of the centroid of the face
! relative from the moment reference point. due to the
! usage of pointers for xx and offset of 1 is present,
! because x originally starts at 0.
        xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j+1&
&         , 1)) - refpoint(1)
        yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j+1&
&         , 2)) - refpoint(2)
        zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j+1&
&         , 3)) - refpoint(3)
! update the viscous force and moment coefficients.
        fv(1) = fv(1) + fx
        fv(2) = fv(2) + fy
        fv(3) = fv(3) + fz
        mx = yc*fz - zc*fy
        my = zc*fx - xc*fz
        mz = xc*fy - yc*fx
        mv(1) = mv(1) + mx
        mv(2) = mv(2) + my
        mv(3) = mv(3) + mz
! save the face based forces for the slice operations
        bcdata(mm)%fv(i, j, 1) = fx
        bcdata(mm)%fv(i, j, 2) = fy
        bcdata(mm)%fv(i, j, 3) = fz
! compute the tangential component of the stress tensor,
! which is needed to monitor y+. the result is stored
! in fx, fy, fz, although it is not really a force.
! as later on only the magnitude of the tangential
! component is important, there is no need to take the
! sign into account (it should be a minus sign).
        fx = tauxx*bcdata(mm)%norm(i, j, 1) + tauxy*bcdata(mm)%norm(i, j&
&         , 2) + tauxz*bcdata(mm)%norm(i, j, 3)
        fy = tauxy*bcdata(mm)%norm(i, j, 1) + tauyy*bcdata(mm)%norm(i, j&
&         , 2) + tauyz*bcdata(mm)%norm(i, j, 3)
        fz = tauxz*bcdata(mm)%norm(i, j, 1) + tauyz*bcdata(mm)%norm(i, j&
&         , 2) + tauzz*bcdata(mm)%norm(i, j, 3)
        fn = fx*bcdata(mm)%norm(i, j, 1) + fy*bcdata(mm)%norm(i, j, 2) +&
&         fz*bcdata(mm)%norm(i, j, 3)
        fx = fx - fn*bcdata(mm)%norm(i, j, 1)
        fy = fy - fn*bcdata(mm)%norm(i, j, 2)
        fz = fz - fn*bcdata(mm)%norm(i, j, 3)
      end do
    else
! compute the local value of y+. due to the usage
! of pointers there is on offset of -1 in dd2wall..
! if we had no viscous force, set the viscous component to zero
      bcdata(mm)%fv = zero
    end if
! increment the local values array with the values we computed here.
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvalues(ifv:ifv+2) = localvalues(ifv:ifv+2) + fv
    localvalues(imp:imp+2) = localvalues(imp:imp+2) + mp
    localvalues(imv:imv+2) = localvalues(imv:imv+2) + mv
    localvalues(isepsensor) = localvalues(isepsensor) + sepsensor
    localvalues(icavitation) = localvalues(icavitation) + cavitation
    localvalues(isepavg:isepavg+2) = localvalues(isepavg:isepavg+2) + &
&     sepsensoravg
  end subroutine forcesandmomentsface
end module surfaceintegrations_d
