pushd "$(dirname "$0")" > /dev/null
SCRIPT_DIR=$(pwd -L)
popd > /dev/null

echo "publish repo YTXRestfulModel"
pod repo push baidao-ios-ytx-pod-specs YTXRestfulModel.podspec --verbose

ret=$?

#exit $ret
