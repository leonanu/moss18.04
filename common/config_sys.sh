#!/bin/bash

## set hostname
if ! grep '^SET_HOSTNAME' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${OS_HOSTNAME}" ];then
        OLD_HOSTNAME=$(hostname)
        hostnamectl set-hostname "${OS_HOSTNAME}"
        if [ -n "$(grep "$OLD_HOSTNAME" /etc/hosts)" ]; then
            sed -i "s/${OLD_HOSTNAME}//g" /etc/hosts
        fi
        sed -i "s/127\.0\.0\.1.*/127.0.0.1    ${OS_HOSTNAME} localhost localhost.localdomain/" /etc/hosts
    fi
    ## log installed tag
    echo 'SET_HOSTNAME' >> ${INST_LOG}
fi

# do not bell on tab-completion
if ! grep '^NO_BELL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep '# set bell-style none' /etc/inputrc > /dev/null 2>&1 ;then
        sed -i '1i\set bell-style none' /etc/inputrc
    else
        sed -i 's/^# set bell-style none/set bell-style none/g' /etc/inputrc
    fi
    NEED_REBOOT=1
    ## log installed tag
    echo 'NO_BELL' >> ${INST_LOG}
fi

## bashrc settings
if ! grep '^SET_BASHRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss bashrc' /etc/bash.bashrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/bash/bashrc >> /etc/bash.bashrc
    fi
    NEED_REBOOT=1
    ## log installed tag
    echo 'SET_BASHRC' >> ${INST_LOG}
fi

## vimrc settings
if ! grep '^SET_VIMRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss vimrc' /etc/vim/vimrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/vi/vimrc >> /etc/vim/vimrc
    fi
    ## log installed tag
    echo 'SET_VIMRC' >> ${INST_LOG}
fi

## disable cron mail
if ! grep '^CRON_MAIL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'MAILTO' /var/spool/cron/crontabs/root > /dev/null 2>&1 ;then
        echo 'MAILTO=""' >> /var/spool/cron/crontabs/root
    fi
    ## log installed tag
    echo 'CRON_MAIL' >> ${INST_LOG}
fi
    
## set root password
if [ ! -z "${OS_ROOT_PASSWD}" ];then
    if ! grep '^SET_ROOT_PASSWORD' ${INST_LOG} > /dev/null 2>&1 ;then
        echo "root:${OS_ROOT_PASSWD}" | chpasswd
        ## log installed tag
        echo 'SET_ROOT_PASSWORD' >> ${INST_LOG}
    fi
fi

## openssh
if ! grep '^OPENSSH' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${SSH_PASS_AUTH} -eq 1 2>/dev/null ]; then
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    fi

    if [ ${SSH_ROOT_LOGIN} -eq 1 2>/dev/null ]; then
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    fi

    systemctl restart ssh.service
    systemctl restart sshd.service
    ## log installed tag
    echo 'OPENSSH' >> ${INST_LOG}
fi

## profiles
if ! grep '^PROFILE' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/profile/history.sh /etc/profile.d/history.sh
    install -m 0644 ${TOP_DIR}/conf/profile/path.sh /etc/profile.d/path.sh
    install -m 0644 ${TOP_DIR}/conf/profile/locale.sh /etc/profile.d/locale.sh
    NEED_REBOOT=1
    ## log installed tag
    echo 'PROFILE' >> ${INST_LOG}
fi

## sysctl
if ! grep '^SYSCTL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss sysctl' /etc/sysctl.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/sysctl/sysctl.conf >> /etc/sysctl.conf
        sysctl -p
        sysctl --system
    fi
    ## log installed tag
    echo 'SYSCTL' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## System Handler
if ! grep '^SYS_HANDLER' ${INST_LOG} > /dev/null 2>&1 ;then
    cat ${TOP_DIR}/conf/os/limits.conf >> /etc/security/limits.conf
    ## log installed tag
    echo 'SYS_HANDLER' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## nscd
if ! grep '^NSCD' ${INST_LOG} > /dev/null 2>&1 ;then
    cp -f /etc/nscd.conf /etc/nscd.conf.ori
    install -m 0644 ${TOP_DIR}/conf/nscd/nscd.conf /etc/nscd.conf
    systemctl restart nscd
    ## log installed tag
    echo 'NSCD' >> ${INST_LOG}
fi

## system service
if ! grep '^SYS_SERVICE' ${INST_LOG} > /dev/null 2>&1 ;then
    for SVC_ON in atd.service cron.service dbus.service irqbalance.service networking.service networkd-dispatcher.service nscd.service ssh.service sshd.service rsyslog.service;do
        systemctl enable ${SVC_ON} 2>/dev/null
        systemctl start ${SVC_ON} 2>/dev/null
    done
    ## log installed tag
    echo 'SYS_SERVICE' >> ${INST_LOG}
fi

## enable rc-local service
if ! grep '^RC-LOCAL' ${INST_LOG} > /dev/null 2>&1 ;then
    chmod 755 /etc/rc.local
    systemctl enable rc-local.service
    systemctl start rc-local.service
    ## log installed tag
    echo 'RC-LOCAL' >> ${INST_LOG}
fi

## create python symbol link for python3
if ! grep '^PY_LINK' ${INST_LOG} > /dev/null 2>&1 ;then
    ln -s /usr/bin/python3.6 /usr/bin/python
    ## log installed tag
    echo 'PY_LINK' >> ${INST_LOG}
fi
