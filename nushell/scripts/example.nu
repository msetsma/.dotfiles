def main [arg] {
  print $"Hello ($arg)!"
}

# How to make nushell scripts executable in Windows 11
# run cmd.exe as administrator and run these 2 commands
# it has to be cmd.exe because ftype and assoc are built-ins on cmd.exe
#
# assoc .nu=NushellScript
# ftype NushellScript=c:\some\path\.cargo\bin\nu.exe %1 %*
#
# note - should make this next part scriptable too
# run regedit.exe with administrator privileges
# go to key HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Environment
# add ;.NU to the PATHEXT key
# This allows you to type "im_executable World" without having to add the .nu extension
# restart cmd.exe/terminal/whatever shell hosting nushell
# Now you should be able to type "im_executable World", assuming im_executable.nu is in the current directory, and it should execute it