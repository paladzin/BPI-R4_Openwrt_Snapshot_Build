# **BPI-R4 - OpenWrt SnapShot Build Script**

This is my test script for compling the latest OpenWRT SnapShot builds which I thought someone else might find usefull so though I'd share it here...

Major update to the original build script, which bings it inline with my other scripts. New script incorperates the "rsync" function to improve the handling of scripts and patches. I've also include a new option to clone the main repos from a local repo.  

# **Updated SnapShot Build Script**

1. You can change branches "openwrt-24.10" , "master" , "main" etc...

2. If you want to build with the latest openwrt-24.10 kernels and the latest mtk commits leave both OPENWRT_COMMIT="" & MTK_FEEDS_COMMIT="" empty.

3. Added a new directories to place all patches and files into "openwrt-patches".
     * e.g.. "openwrt-patches/target/linux/mediatek/patches-6.6/some.patch" will be applied to the "openwrt/target/linux/mediatek/patches-6.6/some.patch" directory.
     * If you want to remove a patch just remove it from the openwrt-patches directory.. e.g. "openwrt-patches/target/linux/mediatek/patches-6.6/some.patch".
	 * Add any custom wireless, network config files to "openwrt-patches/files/etc/config/wireless" and it will be included in the built image.
	 * Add any custom uci-defaults script into "openwrt-patches/files/etc/uci-defaults/" and it will be built into the image.

4. You can place any custom .config files in side the "config" directory to use.

5. Added an option that prompt the usre during the build process to use the "make menuconfig" to add what ever packages or changes you need.
     * When prompted either enter (yes/no): The default is 'no' or let it time out after 10 seconds and it will continue use the existing .config in the config folder.
	 * If 'yes' enter into the make menuconfig and make the changes you need and save, it will continue the build process with your new .config changes.
	 * A new .config.new file will be saved in the config directory.. To make it the default config to use for your next build, just rename it from .config.new to .config

6. Error Checks - All scripts and patches will be auto chacked with dos2unix and corrected if needed. 

7. Permissions - All scripts, patches and folders used will have the correct permissins applied during the build process.

## **Please Note- .gitkeep files and patches**

Please note - No directory with sub folders on github can be empty, so the use of blank ".gitkeep" files are used to create empty sub directories..
            - All .gitkeep files cloned will be deleted on the first excution of the script.. Or just delete them manually if you wish.
			- When using patches. If you have a build fail, read the fail messages and remove the patch causing the error.. 
			- With every new commit files are checnged and patches that work now might not work with next new commit.
			
    - I've left my default patches I use in the repo as examples so delete what you don't want to kept.. before first build
    - If you have the faulty BE14 card with the EEPROM issues.. The two patches are located in "openwrt-patches/package/kernel/mt76/patches/" directory already.
	- If you don't have the faulty BE14 card delete the two patches located in the "openwrt-patches/package/kernel/mt76/patches/" directory.

## **How to Use**

1. **Prerequisites**: Ensure you have a compatible build environment, such as **Ubuntu 24.04 LTS**. You will also need to install `dos2unix`:  
   `sudo apt update`
   
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget dos2unix`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_Openwrt_Snapshot_Build.git`
   
   `sudo chmod 775 -R BPI-R4_Openwrt_Snapshot_Build`

3. **Run the Script**:  
   * Make the script executable:  
     `chmod +x Openwrt_Snapshot.sh`
     
   * Execute the script:  
     `./Openwrt_Snapshot.sh`

## **Notes**
For those with the really bad BE14 cards with the 0 eeprom - You will find the new "9998-kernel-6.12-EEPROM-contains-0s.patch" in the openwrt-patches directory. (may not work with other kernels)

Please note - I've combined the same logic from both original patches into the one patch, so only this one patch is needed.
