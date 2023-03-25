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
        echo "Downloading Firefox Beta $VERSION ..."
        wget --quiet --show-progress -O "firefox-beta-$VERSION.tar.bz2" $FIREFOXPKG
        clear
        echo "Extracting files..."
        tar xvf firefox-beta-$VERSION.tar.bz2
        rm firefox-beta-$VERSION.tar.bz2

    # Move files to Debian package build directory
        mkdir firefox-beta-${VERSION}_${DEBARCH}
        mkdir -p firefox-beta-${VERSION}_${DEBARCH}/usr/share/applications
        mkdir -p firefox-beta${VERSION}_${DEBARCH}/opt
        mv firefox firefox-beta-${VERSION}_${DEBARCH}/opt/firefox

    # Create .deb package of Firefox
        clear
        echo "Preparing to build Firefox installation package ..."
        mkdir firefox-beta-${VERSION}_${DEBARCH}/DEBIAN
        cp ./src-beta/DEBIAN/* firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/
        chmod +x firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/postinst
        chmod +x firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/postrm
        chmod 775 firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/*

        printf "Architecture: $DEBARCH\n" | tee -a firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/control
        printf "Version: $VERSION\n" | tee -a firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/control

        printf "Installed-Size: " >> firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/control | du -sx --exclude DEBIAN firefox-beta-${VERSION}_${DEBARCH} | tee -a firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/control
        sed -i 's/firefox-beta'$VERSION'_'$DEBARCH'//g' firefox-beta-${VERSION}_${DEBARCH}/DEBIAN/control

        cp ./src-beta/launcher/firefox-beta.desktop firefox-beta-${VERSION}_${DEBARCH}/usr/share/applications/firefox-beta.desktop
    
        cd firefox-beta-${VERSION}_${DEBARCH}
        find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
        cd ..

        dpkg-deb --build firefox-beta-${VERSION}_${DEBARCH}
        rm -rf firefox-beta-${VERSION}_${DEBARCH}

    # If --install argument was passed, install the built .deb package
        while test $# -gt 0
        do
            case "$1" in
                --install) 
                clear
                echo "Installing Firefox Beta $VERSION ..."
                sudo dpkg -i firefox-beta-${VERSION}_${DEBARCH}.deb
                echo ""
                    ;;
            esac
            shift
        done

        exit 0
