#!/bin/sh

# **************************************************
# ** Libraries used by Kettle:                    **
# **************************************************

BASEDIR=`dirname $0`
cd $BASEDIR
DIR=`pwd`
cd -

. "$DIR/set-pentaho-env.sh"

setPentahoEnv

CLASSPATH=$BASEDIR
CLASSPATH=$CLASSPATH:$BASEDIR/lib/kettle-core-5.0.1-stable.jar
CLASSPATH=$CLASSPATH:$BASEDIR/lib/kettle-engine-5.0.1-stable.jar

# **************************************************
# ** JDBC & other libraries used by Kettle:       **
# **************************************************

for f in `find $BASEDIR/lib -type f -name "*.jar"` `find $BASEDIR/lib -type f -name "*.zip"`
do
   CLASSPATH=$CLASSPATH:$f
done


# **************************************************
# ** Platform specific libraries ...              **
# **************************************************

OPT="-cp $CLASSPATH"

# ***************
# ** Run...    **
# ***************

"$_PENTAHO_JAVA" $OPT org.pentaho.di.core.encryption.Encr "${1+$@}"




