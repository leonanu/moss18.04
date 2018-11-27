#!/bin/bash

## change atp source
if ! grep '^CH_APT' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${CHANGE_APT} -eq 1 2>/dev/null ]; then
        mv /etc/apt/sources.list /etc/apt/sources.list.ori
        install -m 0644 ${TOP_DIR}/conf/apt/sources.list.aliyun /etc/apt/sources.list
        apt autoclean
        ## log installed tag
        echo 'CH_APT' >> ${INST_LOG}
    fi
fi

## update system
if ! grep '^APT_UPDATE' ${INST_LOG} > /dev/null 2>&1 ;then
    apt update || fail_msg "APT Update Failed!"
    apt upgrade -y || fail_msg "APT Upgrade Failed!"
    ## log installed tag
    echo 'APT_UPDATE' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## install PKGs
if ! grep '^APT_INSTALL' ${INST_LOG} > /dev/null 2>&1 ;then
    PKGS=$(cat ${TOP_DIR}/conf/apt/pkgs.list)
    apt install -y ${PKGS} || fail_msg "Install RPMs Failed!"
    ## log installed tag
    echo 'APT_INSTALL' >> ${INST_LOG}
fi

## install saltstack
#if [ ${INST_SALT} -eq 1 2>/dev/null ]; then
#    if ! grep '^YUM_SALT' ${INST_LOG} > /dev/null 2>&1 ;then
#        succ_msg "Getting SaltStack repository ..."
#        yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm || fail_msg "Getting SaltStack Repository Failed!"
#        echo 'priority=1' >> /etc/yum.repos.d/salt-latest.repo
#        yum clean expire-cache
#        yum install --disablerepo=epel salt-minion -y || fail_msg "SaltStack Minion Install Failed!"
#        [ -f "/etc/salt/minion" ] && rm -f /etc/salt/minion
#        install -m 0644 ${TOP_DIR}/conf/saltstack/minion /etc/salt/minion
#        sed -i "s#^master.*#master: ${SALT_MASTER}#" /etc/salt/minion
#        [ ! -d '/var/log/salt' ] && mkdir -m 0755 -p /var/log/salt
#        systemctl start salt-minion.service
#        systemctl enable salt-minion.service
#        ## log installed tag
#        echo 'YUM_SALT' >> ${INST_LOG}
#    fi
#fi
