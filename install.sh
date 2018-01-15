#!/bin/bash
ETHMINER_VERSION="0.13.0rc6"
ETHMINER="ethminer-$ETHMINER_VERSION-Linux"
AMD_VERSION="amdgpu-pro-17.50-511655"
REQUIRES_REBOOT=false

if groups $whoami | grep &>/dev/null '\bvideo\b'; then
    echo "$whoami in video"
else
    sudo usermod -a -G video $LOGNAME
    echo "you will have to logout or reboot for this group to update"
fi

cd ~/Downloads

if [ ! -f "$AMD_VERSION.tar.xz" ]; then
    echo "downloading $AMD_VERSION drivers"
    wget --referer=http://support.amd.com https://www2.ati.com/drivers/linux/ubuntu/$AMD_VERSION.tar.xz
fi

if [ ! -d $AMD_VERSION ]; then
    echo "decompressing $AMD_VERSION...\n"
    mkdir $AMD_VERSION
    tar -Jxvf $AMD_VERSION.tar.xz
fi

if ! [ -x "$(command -v amdgpu)" ]; then
    echo "do you want to install $AMD_VERSION (y/[n])?"
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
    wget --referer=https://github.com https://github.com/ethereum-mining/ethminer/releases/download/v$ETHMINER_VERSION/$ETHMINER.tar.gz   
fi

if [ ! -d $ETHMINER ]; then
    echo "decompressing $ETHMINER...\n"
    mkdir $ETHMINER
    tar -zxvf $ETHMINER.tar.gz -C $ETHMINER
fi

if [ ! -f "$ETHMINER/start.sh" ]; then
    cd $ETHMINER
    echo "creating start file...\n"

    echo "what is your ETH wallet address? (required)?"
    read ETH_WALLET_ADDRESS

    echo "what is your ETH rig name? (required)?"
    read ETH_RIG_NAME

    echo "export GPU_FORCE_64BIT_PTR=0
    export GPU_MAX_HEAP_SIZE=100
    export GPU_USE_SYNC_OBJECTS=1
    export GPU_MAX_ALLOC_PERCENT=100
    export GPU_SINGLE_ALLOC_PERCENT=100
    bin/ethminer --farm-recheck 200 -G -S eu1.ethermine.org:4444 -FS us1.ethermine.org:4444 -O $ETH_WALLET_ADDRESS.$ETH_RIG_NAME" >> start.sh
    
    chmod +x start.sh
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

if service --status-all | grep 'lightdm'; then
    echo "do you want to disable lightdm service?"
    select result in y n
    do
        if [ $result = "y" ]; then
            sudo systemctl disable lightdm.service
            REQUIRES_REBOOT=true
        else
            echo ""
        fi
        break;
    done
else
    echo ""
fi

if [ $REQUIRES_REBOOT ]; then
    echo "now you need to reboot"
    echo -e "\t$ sudo reboot"
fi

echo "done"