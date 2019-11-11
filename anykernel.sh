# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Genom Kernel by rama982 @ telegram
do.devicecheck=1
do.modules=1
do.cleanup=1
do.cleanuponabort=0
device.name1=lavender
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=9 - 10
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


# Key select start
ui_print " "
ui_print "Touch the screen first or press any volume key"

INSTALLER=$(pwd)
KEYCHECK=$INSTALLER/tools/keycheck
chmod 755 $KEYCHECK

keytest() {
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

choose() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while true; do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}

if [ -z $NEW ]; then
  if keytest; then
    FUNCTION=choose
  else
    FUNCTION=chooseold
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Volume Up Key: "
    $FUNCTION "UP"
    ui_print "   Press Volume Down Key: "
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Option -"
  ui_print "   Choose the big CPU clock rate you want:"
  ui_print "   Volume Up = 1.95 GHz, Volume Down = 2.2 GHz"
  if $FUNCTION; then
    NEW=true
  else
    NEW=false
  fi
else
  ui_print "   Option specified in zipname!"
fi
# Key select end


## AnyKernel install
dump_boot;


# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.gz
if [ -f $compressed_image ]; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot --decompress $compressed_image $decompressed_image;
    $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
    $bin/magiskboot --compress=gzip $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  if $NEW; then
    cat $compressed_image /tmp/anykernel/dtbs/*.dtb-uc > /tmp/anykernel/Image.gz-dtb;
  else
    cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.gz-dtb;
  fi
fi;


write_boot;
## end install

