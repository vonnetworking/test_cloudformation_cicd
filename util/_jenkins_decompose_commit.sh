

#print the yaml or bootstrap files changed since last merge on observed branch
#                                     #use second parent                  #grab just bootstrap, param, or yaml files
CHANGED_FILES=`git diff $(git log | grep Merge: | awk '{print $3}') --name-status | grep -e bootstrap -e yaml -e params | awk '{print $NF}'`

IFS=$'\n'
mkdir ./stage
for F in $CHANGED_FILES; do
  PKG_BASE=`echo $(basename $F | awk -F'.' '{print $1}')`

  find .. -name ${PKG_BASE}* | zip -r -@ ./stage/${PKG_BASE}.zip
done
