#shit box

VM_NAME=$(VBoxManage list runningvms | awk -F'"' '{print $2}' | head -1)
VBoxManage controlvm "$VM_NAME" savestate
echo "Waiting minute..."; sleep 60
vagrant up