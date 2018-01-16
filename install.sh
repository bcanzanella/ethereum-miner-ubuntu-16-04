#!/bin/bash
ETHMINER_VERSION="0.13.0rc6"
ETHMINER="ethminer-$ETHMINER_VERSION-Linux"
CLAYMORE_VERSION="10.4"
CLAYMORE_MINER="claymore-v$CLAYMORE_VERSION"
AMD_VERSION="amdgpu-pro-17.50-511655"
REQUIRES_REBOOT=false

ETH_WALLET_ADDRESS=""
ETH_RIG_NAME=""
DECRED_WALLET_ADDRESS=""

#sudo apt update
#sudo apt install --assume-yes clinfo

if groups $whoami | grep &>/dev/null '\bvideo\b'; then
    echo ""
else
    sudo usermod -a -G video $LOGNAME
    echo "added '$LOGNAME' to 'video'. you will have to logout or reboot for this group to update"
fi

cd ~/Downloads

if [ ! -f "$AMD_VERSION.tar.xz" ]; then
    echo "downloading $AMD_VERSION drivers"
    wget --referer=http://support.amd.com https://www2.ati.com/drivers/linux/ubuntu/$AMD_VERSION.tar.xz
fi

if [ ! -d $AMD_VERSION ]; then
    echo "decompressing $AMD_VERSION..."
    mkdir $AMD_VERSION
    tar -Jxvf $AMD_VERSION.tar.xz
fi

if ! [ -x "$(command -v amdgpu)" ]; then
    echo "do you want to install $AMD_VERSION?"
    select result in y n
    do
        if [ $result = "y" ]; then
            cd $AMD_VERSION
            echo "installing $AMD_VERSION..."
            ./amdgpu-pro-install --opencl=legacy,rocm --headless
            REQUIRES_REBOOT=true
        else
            echo ""
        fi
        break;
    done
fi

cd ~/Downloads

if [ ! -f "$ETHMINER.tar.gz" ]; then
    echo "downloading $ETHMINER..."
    wget --quiet --referer=https://github.com https://github.com/ethereum-mining/ethminer/releases/download/v$ETHMINER_VERSION/$ETHMINER.tar.gz   
fi

if [ ! -d $ETHMINER ]; then
    echo -e "decompressing $ETHMINER...\n"
    mkdir $ETHMINER
    tar -zxvf $ETHMINER.tar.gz -C $ETHMINER
fi

if [ ! -f "$CLAYMORE_MINER.tar.gz" ]; then
  wget --content-disposition --quiet https://github.com/bcanzanella/ethereum-miner-ubuntu-16-04/blob/master/installers/claymore-v$CLAYMORE_VERSION.tar.gz?raw=true
fi

if [ ! -d $CLAYMORE_MINER ]; then
    echo -e "decompressing $CLAYMORE_MINER...\n"
    mkdir $CLAYMORE_MINER
    tar -zxvf $CLAYMORE_MINER.tar.gz --strip-components 1 -C $CLAYMORE_MINER
fi

if [ ! -f "start_ethminer.sh" ] || [ ! -f "start_claymore.sh" ]; then
    echo "creating start files...\n"

    echo "what is your ETH wallet address? (required)?"
    read ETH_WALLET_ADDRESS

    echo "what is your ETH rig name? (required)?"
    read ETH_RIG_NAME
fi

if [ ! -f "start_ethminer.sh" ]; then
    echo "export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export GPU_FORCE_64BIT_PTR=1

./$ETHMINER/bin/ethminer --farm-recheck 200 -G -S eu1.ethermine.org:4444 -FS us1.ethermine.org:4444 -O $ETH_WALLET_ADDRESS.$ETH_RIG_NAME" > start_ethminer.sh
    chmod +x ./start_ethminer.sh
fi

if [ ! -f "start_claymore.sh" ]; then
    CLAYMORE="export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export GPU_FORCE_64BIT_PTR=1

./$CLAYMORE_MINER/ethdcrminer64 -epool us1.ethermine.org:4444 -ewal 0x$ETH_WALLET_ADDRESS.$ETH_RIG_NAME -epsw x"

    echo "what is your DECRED wallet address? (optional)?"
    read DECRED_WALLET_ADDRESS

    if [ ! DECRED_WALLET_ADDRESS = "" ]; then
        CLAYMORE="$CLAYMORE -dpool stratum+tcp://yiimp.ccminer.org:3252 -dwal $DECRED_WALLET_ADDRESS -dpsw x"
    fi

    echo "$CLAYMORE" > start_claymore.sh
    chmod +x ./start_claymore.sh
fi

if grep "amdgpu" "/etc/default/grub"; then
    echo ""
else
    echo "Need to add 'amdgpu.vm_fragment_size=9' to 'GRUB_CMDLINE_LINUX_DEFAULT'"
    echo -e "\t$ sudo nano /etc/default/grub"
    echo -e "\t$ sudo update-grub"
    echo ""
    REQUIRES_REBOOT=true
    #sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT\="\w*?/& amdgpu.vm_fragment_size=9/' /etc/default/grub
    #sudo update-grub
fi

# if service --status-all | grep 'lightdm'; then
#     echo "do you want to disable lightdm service?"
#     select result in y n
#     do
#         if [ $result = "y" ]; then
#             sudo systemctl disable lightdm.service
#             REQUIRES_REBOOT=true
#         else
#             echo ""
#         fi
#         break;
#     done
# else
#     echo ""
# fi

if [ $REQUIRES_REBOOT ]; then
    echo "now you need to reboot"
    echo -e "\t$ sudo reboot"
fi

echo "done"