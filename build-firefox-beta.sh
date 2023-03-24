#!/bin/bash

# Firefox son sürüm (Türkçe) .deb paketleme scpriti
   
        # Architecture
        FXOS=linux64
        FXARCH=x86_64
        DEBARCH=amd64
            
        # Release channel
        FXCHANNEL=firefox-beta-latest-ssl
        FXDIR=firefox
           

    # Check for the latest version of Firefox
        VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=${FXCHANNEL}&os=${FXOS}&lang=tr" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}

    # Set download URL
        FIREFOXPKG="https://download-installer.cdn.mozilla.net/pub/${FXDIR}/releases/${VERSION}/linux-${FXARCH}/tr/firefox-${VERSION}.tar.bz2"

    # Download and extract the latest Firefox release package
        clear
        echo "Downloading Firefox $VERSION ..."
        wget --quiet --show-progress -O "firefox-$VERSION.tar.bz2" $FIREFOXPKG
        clear
        echo "Extracting files..."
        tar xvf firefox-$VERSION.tar.bz2
        rm firefox-$VERSION.tar.bz2

    # Move files to Debian package build directory
        mkdir firefox-${VERSION}_${DEBARCH}
        mkdir -p firefox-${VERSION}_${DEBARCH}/usr/share/applications
        mkdir -p firefox-${VERSION}_${DEBARCH}/opt
        mv firefox firefox-${VERSION}_${DEBARCH}/opt/firefox

    # Create .deb package of Firefox
        clear
        echo "Preparing to build Firefox installation package ..."
        mkdir firefox-${VERSION}_${DEBARCH}/DEBIAN
        cp ./src/DEBIAN/* firefox-${VERSION}_${DEBARCH}/DEBIAN/
        chmod +x firefox-${VERSION}_${DEBARCH}/DEBIAN/postinst
        chmod +x firefox-${VERSION}_${DEBARCH}/DEBIAN/postrm
        chmod 775 firefox-${VERSION}_${DEBARCH}/DEBIAN/*

        printf "Architecture: $DEBARCH\n" | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control
        printf "Version: $VERSION\n" | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control

        printf "Installed-Size: " >> firefox-${VERSION}_${DEBARCH}/DEBIAN/control | du -sx --exclude DEBIAN firefox-${VERSION}_${DEBARCH} | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control
        sed -i 's/firefox-'$VERSION'_'$DEBARCH'//g' firefox-${VERSION}_${DEBARCH}/DEBIAN/control

        cp ./src/launcher/firefox.desktop firefox-${VERSION}_${DEBARCH}/usr/share/applications/firefox.desktop
    
        cd firefox-${VERSION}_${DEBARCH}
        find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
        cd ..

        dpkg-deb --build firefox-${VERSION}_${DEBARCH}
        rm -rf firefox-${VERSION}_${DEBARCH}

    # If --install argument was passed, install the built .deb package
        while test $# -gt 0
        do
            case "$1" in
                --install) 
                clear
                echo "Installing Firefox $VERSION ..."
                sudo dpkg -i firefox-${VERSION}_${DEBARCH}.deb
                echo ""
                    ;;
            esac
            shift
        done

        exit 0
