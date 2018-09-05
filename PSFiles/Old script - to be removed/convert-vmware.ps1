Import-Module 'C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1'

$source = 'C:\Users\pierrer\Downloads\E.F.A.3.0.0.8-VMware\E.F.A.3.0.0.8-VMware\Email Filter Appliance\Email_Filter_Appliance-disk1.vmdk'

ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath $source -VhdType FixedHardDisk -VhdFormat vhd -destination c:\vm-disk1