mkdir -p ./bin/linux_amd64-debug
odin build src -strict-style -debug -out:bin/linux_amd64-debug/App -target:linux_amd64 -keep-temp-files -o:none -show-timings
chmod u+x ./bin/linux_amd64-debug
