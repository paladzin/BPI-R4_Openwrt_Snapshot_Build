# **BPI-R4 - OpenWrt SnapShot Build Script**

This is my test script for compling the latest OpenWRT SnapShot builds which I thought someone else might find usefull so though I'd share it here...

The Sctipt is very similar to all my other auto scripts, except this script you set the branch and it will automaticly find the latest commit on that branch to build.

Its a set and forget script, once set with all your custom settings all you have to do is just run it to get the latest up to date snapshot.

1. You can change branches like "openwrt-24.10" , "master" , "main" etc...

2. You can use custom patches 

3. You can use uci-defaults scripts

4. You can also add already configered config files (e.g., shadow, network) into the files/etc/ or files/config/ directories.

5. And for build config, you can add what ever packages you need to the .config in config folder such as **CONFIG_WIFI_SCRIPTS_UCODE=y** etc


## **How to Use**

1. **Prerequisites**: Ensure you have a compatible build environment, such as **Ubuntu 24.04 LTS**. You will also need to install `dos2unix`:  
   `sudo apt update`
   
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \\`
   
   `gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev \\`
   
   `file wget dos2unix`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_Openwrt_Snapshot_Build.git`
   
   `sudo chmod 776 -R Openwrt_Snapshot.sh`

3. **Prepare Your Custom Files**:  
   * Place any custom patches you want to apply into the patches/ directory.  
   * Place your final configuration files (e.g., shadow, network) into the files/etc/ or files/config/ directories.  
   * If you have a first-boot uci-fefaults script, place it in the scripts/ directory.  
4. **Configure the Build Script**:  
   * Open the build script (e.g., Openwrt_Snapshot.sh) in a text editor.  
   * At the top of the file, set the `SETUP\_SCRIPT\_NAME` variable to the name of your first-boot script, or leave it as "" to disable it.  
   * Review the apply\_patches function to enable or disable any patches by commenting or uncommenting the cp commands.  
5. **Run the Script**:  
   * Make the script executable:  
     `chmod \+x Openwrt_Snapshot.sh`
     
   * Execute the script:  
     `./Openwrt_Snapshot.sh`

## **Notes**
Please note - I use this script for testing new snapshots etc... Snapshot builds can be unstable and problematic using them on a main router.