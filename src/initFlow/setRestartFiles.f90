!
!      ******************************************************************
!      *                                                                *
!      * File:          setRestartFiles.f90                           *
!      * Author:        Eirikur Jonsson                                 *
!      *                                                                *
!      ******************************************************************
!
subroutine setRestartFiles(fileName,i)
  !
  !      ******************************************************************
  !      *    Populates the restartfiles                                  *
  !      *    The array is populated from Python using setRestartFiles    *
  !      ******************************************************************
  !
  use constants
  use inputIO
  use inputTimeSpectral
  implicit none
  !
  !      Subroutine argument.
  !
  character(len=*), intent(inout) :: fileName
  integer(kind=intType) :: i

  !      ******************************************************************
  !      *                                                                *
  !      * Begin execution                                                *
  !      *                                                                *
  !      ******************************************************************
  !

  restartFiles(i) = fileName

end subroutine setRestartFiles
