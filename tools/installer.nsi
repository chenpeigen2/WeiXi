; WeiXi Windows 安装包（makensis tools/installer.nsi）
Unicode true
!include "MUI2.nsh"

Name "WeiXi 玩不死的泡泡龙"
OutFile "..\export\WeiXiSetup.exe"
InstallDir "$PROGRAMFILES64\WeiXi"
InstallDirRegKey HKLM "Software\WeiXi" "InstallDir"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "安装" SecMain
  SetOutPath "$INSTDIR"
  File /r "..\export\windows\*.*"
  WriteRegStr HKLM "Software\WeiXi" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WeiXi" "DisplayName" "WeiXi 玩不死的泡泡龙"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WeiXi" "UninstallString" "$INSTDIR\uninstall.exe"
  CreateShortCut "$SMPROGRAMS\WeiXi.lnk" "$INSTDIR\weixi.exe"
  CreateShortCut "$DESKTOP\WeiXi.lnk" "$INSTDIR\weixi.exe"
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\WeiXi.lnk"
  Delete "$DESKTOP\WeiXi.lnk"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WeiXi"
  DeleteRegKey HKLM "Software\WeiXi"
SectionEnd
