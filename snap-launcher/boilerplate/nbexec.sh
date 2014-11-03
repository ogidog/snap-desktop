#!/bin/sh
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright 1997-2014 Oracle and/or its affiliates. All rights reserved.
#
# Oracle and Java are registered trademarks of Oracle and/or its affiliates.
# Other names may be trademarks of their respective owners.
#
# The contents of this file are subject to the terms of either the GNU
# General Public License Version 2 only ("GPL") or the Common
# Development and Distribution License("CDDL") (collectively, the
# "License"). You may not use this file except in compliance with the
# License. You can obtain a copy of the License at
# http://www.netbeans.org/cddl-gplv2.html
# or nbbuild/licenses/CDDL-GPL-2-CP. See the License for the
# specific language governing permissions and limitations under the
# License.  When distributing the software, include this License Header
# Notice in each file and include the License file at
# nbbuild/licenses/CDDL-GPL-2-CP.  Oracle designates this
# particular file as subject to the "Classpath" exception as provided
# by Oracle in the GPL Version 2 section of the License file that
# accompanied this code. If applicable, add the following below the
# License Header, with the fields enclosed by brackets [] replaced by
# your own identifying information:
# "Portions Copyrighted [year] [name of copyright owner]"
#
# Contributor(s):
#
# The Original Software is NetBeans. The Initial Developer of the Original
# Software is Sun Microsystems, Inc. Portions Copyright 1997-2011 Sun
# Microsystems, Inc. All Rights Reserved.
#
# If you wish your version of this file to be governed by only the CDDL
# or only the GPL Version 2, indicate your decision by adding
# "[Contributor] elects to include this software in this distribution
# under the [CDDL or GPL Version 2] license." If you do not indicate a
# single choice of license, a recipient has the option to distribute
# your version of this file under either the CDDL, the GPL Version 2 or
# to extend the choice of license to its licensees as provided above.
# However, if you add GPL Version 2 code and therefore, elected the GPL
# Version 2 license, then the option applies only if the new code is
# made subject to such option by the copyright holder.


PRG=$0


resolve_symlink () {
    file="$1"
    while [ -h "$file" ]; do
        ls=`ls -ld "$file"`
        link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
        if expr "$link" : '^/' 2> /dev/null >/dev/null; then
            file="$link"
        else
            file=`dirname "$1"`"/$link"
        fi
    done
    echo "$file"
}

absolutize_path () {
    oldpwd=`pwd`
    cd "$1"
    abspath=`pwd`
    cd "${oldpwd}"
    echo "$abspath"
}

PRG=`resolve_symlink "$PRG"`
progdir=`dirname "$PRG"`
plathome=`absolutize_path "$progdir/.."`

jargs=${jreflags}
jargs="$jargs -Dnetbeans.home=\"$plathome\""

args=""

launcher_args=""

prefixcp=""
postfixcp=""

updater_class=org.netbeans.updater.UpdaterFrame

#
# parse arguments
#

parse_args() {
while [ $# -gt 0 ] ; do
    case "$1" in
        -h|-\?|-help|--help) cat >&2 <<EOF
Usage: $0 {options} arguments

General options:
  --help                show this help 
  --jdkhome <path>      path to Java(TM) 2 SDK, Standard Edition
  -J<jvm_option>        pass <jvm_option> to JVM

  --cp:p <classpath>    prepend <classpath> to classpath
  --cp:a <classpath>    append <classpath> to classpath
EOF
            # go on and print IDE options as well
        args="$args --help"
            ;;
        --nosplash)
            nosplash="nosplash";
            args="$args --nosplash"
            ;;
        --jdkhome) shift; if [ $# -gt 0 ] ; then jdkhome=$1; fi
            ;;
        # this has to be here for purposes of updater.jar, but it should be
        # better to handle this argument inside the java launcher part 
        --userdir) shift; if [ $# -gt 0 ] ; then userdir="$1"; fi
            ;;
        --cachedir) shift; if [ $# -gt 0 ] ; then cachedir="$1"; cachedirspecified="specified" ; fi
            ;;
        -cp|-cp:a|--cp|--cp:a)
            shift;
            if [ $# -gt 0 ] ; then
                if [ ! -z "$postfixcp" ] ; then postfixcp="$postfixcp:" ; fi
                postfixcp=$postfixcp$1;
            fi
            ;;
        
        -cp:p|--cp:p)
            shift;
            if [ $# -gt 0 ] ; then
                if [ ! -z "$prefixcp" ] ; then prefixcp="$prefixcp:" ; fi
                prefixcp=$prefixcp$1;
            fi
            ;;
        --clusters)
            shift;
            if [ $# -gt 0 ] ; then
                clusters="$1"
            fi
            ;;
        -psn*)
            shift;
            ;;
	-L*) lopt=`expr "X-$1" : 'X--L\(.*\)'`; launcher_args="$launcher_args '$lopt'";;
        -J*) jopt=`expr "X-$1" : 'X--J\(.*\)'`; jargs="$jargs '$jopt'";;
        *) args="$args \"$1\"" ;;
    esac
    shift
done
} # parse_args()

# Process arguments given on the command line.
parse_args "$@"

#
# check JDK
#

if [ -z "$jdkhome" ] ; then
    # try to find JDK
    case "`uname`" in
        Darwin*)
        # read Java Preferences
        if [ -x "/usr/libexec/java_home" ]; then
            jdkhome=`/usr/libexec/java_home --version 1.7.0_10+ --failfast`

        # JDK1.7 Update 10 as a fallback
        elif [ -f "/Library/Java/JavaVirtualMachines/jdk1.7.0_10.jdk/Contents/Home/bin/java" ] ; then
            jdkhome="/Library/Java/JavaVirtualMachines/jdk1.7.0_10.jdk/Contents/Home"
        fi         
   
        # JRE fallback
        if [ ! -x "${jdkhome}/bin/java" -a -f "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java" ] ; then
            jdkhome="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
        fi
        ;;
        *) javac=`which javac`
        if [ -z "$javac" ] ; then
            java=`which java`
            if [ ! -z "$java" ] ; then
                java=`resolve_symlink "$java"`
                jdkhome=`dirname $java`"/.."
            fi
        else
            javac=`resolve_symlink "$javac"`
            jdkhome=`dirname $javac`"/.."
        fi
        ;;
    esac
fi

if [ ! -x "${jdkhome}/bin/java" ] ; then
    echo "Cannot find java. Please use the --jdkhome switch." >&2
    exit 2
fi

if [ -n "$launcher_args" ] ; then
    case "`uname`" in
        SunOS*) awk=nawk ;;
        *) awk=awk ;;
    esac
    jdk_version=$("${jdkhome}/bin/java" -version 2>&1 | "/usr/bin/${awk}" -F '"' '/version/ {print substr($2, 1, 3)}')    
    if [ "$jdk_version" = "1.7" ] ; then   
        jargs="$jargs $launcher_args"
    fi
fi


# Make sure native code libraries of jdk7 are found
# setting of the LD_LIBRARY_PATH is unnecessary on JDK8, and should be removed when only JDK8 is supported:
case "`uname`" in
    SunOS*)
        LD_LIBRARY_PATH=${jdkhome}/jre/lib/amd64/client:${jdkhome}/jre/lib/amd64/server:${jdkhome}/jre/lib/i386/client:${jdkhome}/jre/lib/i386/server:${LD_LIBRARY_PATH}
        export LD_LIBRARY_PATH
        ;;
    *)
        LD_LIBRARY_PATH=${jdkhome}/jre/lib/amd64:${jdkhome}/jre/lib/i386:${LD_LIBRARY_PATH}
        export LD_LIBRARY_PATH
        ;;
esac

# fixes 225762: Can't open project from a folder with UTF-8 letters on Mac OS X
if [ `uname` = "Darwin" ] ; then
    if [ x${LC_CTYPE} = x ] ; then
        export LC_CTYPE=UTF-8;
    fi
fi

jargs="$jargs -XX:+HeapDumpOnOutOfMemoryError"
if [ -z "`echo $jargs | grep -- "-XX:HeapDumpPath="`" ] ; then
  jargs="$jargs -XX:HeapDumpPath=\"${userdir}/var/log/heapdump.hprof\""
fi
# rename old heap dump to .old
mv "${userdir}/var/log/heapdump.hprof" "${userdir}/var/log/heapdump.hprof.old" > /dev/null 2>&1

jargs_without_clusters="$jargs"
jargs="-Dnetbeans.dirs=\"${clusters}\" $jargs_without_clusters"

if [ -z "$cachedirspecified" ]; then
   cachedir="${userdir}/var/cache"
fi

if [ `uname` != Darwin -a -z "$nosplash" -a -f "${cachedir}/splash.png" -a ! -f "${userdir}/lock" ]; then
   jargs="$jargs -splash:\"${cachedir}/splash.png\""
fi

jdkhome=`absolutize_path "$jdkhome"`

args="--userdir \"${userdir}\" $args"

args="--cachedir \"${cachedir}\" $args"

append_jars_to_cp() {
    dir="$1"
    subpath="$2"
    for ex in jar zip ; do
        if [ "`echo "${dir}"/*.$ex`" != "${dir}/*.$ex" ] ; then
            for x in "${dir}"/*.$ex ; do
                subx=`basename "$x"`
                if [ -z "`echo "$paths" | egrep "$subpath$subx"`" ] ; then
                    if [ ! -z "$cp" ] ; then cp="$cp:" ; fi
                    cp="$cp$x"
                    if [ ! -z "$paths" ] ; then paths="$paths:" ; fi
                    paths="$paths$subpath$subx"
                fi
            done
        fi
    done
}

construct_cp() {
    cp=""
    updatercp=""
    paths=""
    
    build_cp "${userdir}"
    build_cp "${plathome}"
    
    if [ -f "${userdir}/modules/ext/updater.jar" ] ; then
        updatercp="${userdir}/modules/ext/updater.jar"
    else 
        if [ -f "${plathome}/modules/ext/updater.jar" ] ; then
            updatercp="${plathome}/modules/ext/updater.jar"
        fi
    fi

    # JDK tools
    for x in "${jdkhome}/lib/dt.jar" "${jdkhome}/lib/tools.jar"; do
        if [ -f "$x" ]; then
            if [ ! -z "$cp" ] ; then cp="$cp:" ; fi
            cp="${cp}$x"
        fi
    done

    # user-specified prefix and postfix CLASSPATH
    
    if [ ! -z "${prefixcp}" ] ; then
        cp="${prefixcp}:$cp"
    fi
    
    if [ ! -z "${postfixcp}" ] ; then
        cp="$cp:${postfixcp}"
    fi


    # prepend IDE's classpath to updater's classpath
    # (just xml-apis.jar and one XML parser would suffice)
    if [ ! -z "$updatercp" ] ; then
        updatercp=${cp}:${updatercp}
    else
        updatercp=${cp}
    fi
}

build_cp() {
    base="$1"
    append_jars_to_cp "${base}/lib/patches" "patches"
    append_jars_to_cp "${base}/lib" "lib"
    append_jars_to_cp "${base}/lib/locale" "locale"
}

do_run_updater() {
    eval "\"$jdkhome/bin/java\"" -classpath "\"${updatercp}\"" "$jargs" "-Dnetbeans.user=\"$userdir\"" $updater_class "$args"
    construct_cp
}

look_for_pre_runs() {
    base="$1"
    install_new_updater "$1"
    dir="${base}/update/download"
    if [ "`echo "${dir}"/*.nbm`" != "${dir}/*.nbm" -o "`echo "${dir}"/*.jar`" != "${dir}/*.jar" ] ; then
        run_updater=yes
    else
        dir="${base}/update/deactivate"
        if [ -f "${dir}/to_disable.txt" -o -f "${dir}/to_uninstall.txt" ] ; then
            run_updater=yes
        fi
    fi
}

look_for_post_runs() {
    base="$1"
    install_new_updater "$1"
    dir="${base}/update/download"
    if [ \! -f "${dir}/install_later.xml" ] && [ "`echo "${dir}"/*.nbm`" != "${dir}/*.nbm" -o "`echo "${dir}"/*.jar`" != "${dir}/*.jar" ] ; then
        run_updater=yes
    else
        dir="${base}/update/deactivate"
        if [ \! -f "${dir}/deactivate_later.txt" ] ; then
            if [ -f "${dir}/to_disable.txt" -o -f "${dir}/to_uninstall.txt" ] ; then
                run_updater=yes
            fi
        fi
    fi
}

look_for_new_clusters() {
    base="$userdir"
    dir="${base}/update/download"
    newclusters="${dir}/netbeans.dirs"
    if [ -f "${newclusters}" ] ; then
        clusters=`cat "${newclusters}"`
        jargs="-Dnetbeans.dirs=\"${clusters}\" $jargs_without_clusters"
        rm -f "${newclusters}"
    fi
}

delete_new_clusters_file() {
    base="$userdir"
    dir="${base}/update/download"
    newclusters="${dir}/netbeans.dirs"
    if [ \! -f "${newclusters}" ] ; then
        rm -f "${newclusters}"
    fi
}

install_new_updater() {
    base="$1"
    newUpdaterDir="${base}/update/new_updater"
    if [ -d "${newUpdaterDir}" ]; then
        mkdir -p "${base}/modules/ext/"
        if [ -f "${newUpdaterDir}/updater.jar" ]; then
            mv -f "${newUpdaterDir}/updater.jar" "${base}/modules/ext/"
        fi
        for i in "${newUpdaterDir}/locale/"updater_*.jar; do
            if [ -f "$i" ]; then
                mkdir -p "${base}/modules/ext/locale/"
                mv -f "$i" "${base}/modules/ext/locale/"
            fi
        done
        rmdir "${newUpdaterDir}"
    fi
}

if [ "$KDE_FULL_SESSION" = "true" ] ; then
    jargs="-Dnetbeans.running.environment=kde $jargs"        
else
    if [ ! -z "$GNOME_DESKTOP_SESSION_ID" ] ; then
        jargs="-Dnetbeans.running.environment=gnome $jargs" 
    fi
fi

if [ ! -z "${DEFAULT_USERDIR_ROOT}" ] ; then
	jargs="-Dnetbeans.default_userdir_root=\"${DEFAULT_USERDIR_ROOT}\" $jargs"
        unset DEFAULT_USERDIR_ROOT
fi

# http://java.sun.com/j2se/1.5.0/docs/guide/2d/flags.html#pixmaps
J2D_PIXMAPS=shared
export J2D_PIXMAPS

# Check DISPLAY variable on non-Mac
if [ "no$DISPLAY" = "no" -a `uname` != Darwin ]; then
    echo "$0: WARNING: environment variable DISPLAY is not set"
fi


# The Startup Notification Protocol Specification [1]
# recommends to unset the DESKTOP_STARTUP_ID environment variable 
# to avoid possible reuse by some process started later by this
# process, e.g. when a browser will be launched by the NetBeans [2].
#
# See:
# [1] http://standards.freedesktop.org/startup-notification-spec
# [2] http://netbeans.org/bugzilla/show_bug.cgi?id=76970
if [ ! -z "$DESKTOP_STARTUP_ID" ] ; then
    # Save a value for later using
    NB_DESKTOP_STARTUP_ID="$DESKTOP_STARTUP_ID"; export NB_DESKTOP_STARTUP_ID

    unset DESKTOP_STARTUP_ID
fi


#
# main loop
#

# clear to prevent loop from ending
restart="yes"
first_time_starting="yes"
restart_file="${userdir}/var/restart"

while [ "$restart" ] ; do

    #
    # build CLASSPATH
    #
    construct_cp
    
    # First check for pre-run updates.
    if [ "$first_time_starting" ] ; then
        run_updater=""
        look_for_pre_runs "$plathome"
        save="$IFS"
        IFS=':' ; for oneCls in $clusters ; do
            IFS="$save"
            look_for_pre_runs "$oneCls"
        done
        IFS="$save"
        look_for_pre_runs "$userdir"
        if [ "$run_updater" ] ; then do_run_updater ; fi
        # Do not check this after a restart, it makes no sense.
        first_time_starting=""
    fi
    
    #
    # let's go
    #
    delete_new_clusters_file
    rm -f "${restart_file}"
    eval ${_NB_PROFILE_CMD} "\"${jdkhome}/bin/java\"" -Djdk.home="\"${jdkhome}\"" -classpath "\"$cp\"" \
        "$jargs" org.netbeans.Main "$args" '<&0' '&'
    PID=$!
    trap "kill $PID" EXIT
    wait $PID
    exitcode=$?
    trap '' EXIT
    look_for_new_clusters
    # If we should update anything, do it and restart IDE.
    run_updater=""
    look_for_post_runs "$plathome"

    save="$IFS"
    IFS=':' ; for oneCls in $clusters ; do
        IFS="$save"
        look_for_post_runs "$oneCls"
    done
    IFS="$save"
    look_for_post_runs "$userdir"
    if [ "$run_updater" ] ; then
        do_run_updater
        restart="yes"
    else
        if [ ! -f "${restart_file}" ] ; then
            # will fall thru loop and exit
            restart=""
        fi
    fi

done

# and we exit.
exit $exitcode
