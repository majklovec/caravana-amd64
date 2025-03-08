for item in base file mysql postgres firebird ; do
  cd ./$item
  ./build.sh
  cd ..
done

