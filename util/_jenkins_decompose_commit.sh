

#print the yaml, bootstrap, or param files changed since last merge on observed branch
export CHANGED_BOOTSTRAPS=`git diff $(git log | grep Merge: | awk '{print $3}') --name-status | grep -e bootstrap | awk -F'/' '{print $3}'`
export CHANGED_YAMLS=`git diff $(git log | grep Merge: | awk '{print $3}') --name-status | grep -e yaml | awk '{print $NF}'`
export CHANGED_PARAMS=`git diff $(git log | grep Merge: | awk '{print $3}') --name-status | grep -e param | awk '{print $NF}' | awk -F'_' '{print $1}'`

IFS=$'\n'

rm -rf ./stage
mkdir ./stage
rm -rf ./sync
rm -rf ./sync

for F in $CHANGED_YAMLS; do
  PKG_BASE=`echo $(basename $F | awk -F'.' '{print $1}')`
  echo "$PKG_BASE"
  pwd
  find . -name ${PKG_BASE}* | zip -r -@ ./stage/${PKG_BASE}.zip
done

for F in $CHANGED_BOOTSTRAPS; do
  PKG_BASE=`echo $(basename $F | awk -F'.' '{print $1}')`
  echo "$PKG_BASE"
  pwd
  find . -name ${PKG_BASE}* | zip -r -@ ./stage/${PKG_BASE}.zip
done

for F in $CHANGED_PARAMS; do
  PKG_BASE=`echo $(basename $F | awk -F'.' '{print $1}')`
  echo "$PKG_BASE"
  pwd
  find . -name ${PKG_BASE}* | zip -r -@ ./stage/${PKG_BASE}.zip
done
