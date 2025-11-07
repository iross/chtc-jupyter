cat > /tmp/test_output.sh << 'EOF'
#!/bin/bash
ssh -L 8889:localhost:8889 iaross@ap2002.chtc.wisc.edu bash << 'EOFAP'
temp_ssh=$(mktemp)
cat > "$temp_ssh" << 'EOFSSH'
#!/bin/bash
exec ssh -L 8889:localhost:8889 "$@"
EOFSSH
chmod +x "$temp_ssh"

echo "About to connect to job..."
condor_ssh_to_job -auto-retry -ssh "$temp_ssh" 4599002 << 'EOFEP'
echo "Connected! Now launching jupyter..."
[[ -f /opt/conda/bin/activate ]] && source /opt/conda/bin/activate
./launch_jupyter.sh 8889
EOFEP

rm -f "$temp_ssh"
EOFAP
EOF

bash /tmp/test_output.sh
