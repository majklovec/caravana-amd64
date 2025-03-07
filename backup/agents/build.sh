for item in base mysql postgres firebird ; do
  cd ./$item
  ./build.sh
  cd ..
done

