The dracut-uefi install and remove scripts are now controlled by the
initramfs alternative group. To use dracut-uefi to generate unified
kernel image initramfses, run:

	dulge-alternatives -s dracut-uefi

Then (re)generate the UKIs with:

	dulge-reconfigure -f linux6.Y
