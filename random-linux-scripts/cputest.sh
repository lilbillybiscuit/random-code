if lscpu | grep -q AMD; then
    export ARCH="AMD"
elif lscpu | grep -q Intel; then
    export ARCH="Intel"
else # neither Intel nor AMD
    export ARCH="ARM"
fi
echo $ARCH
