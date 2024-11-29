i=0

echo "0" > inputs.txt

for i in {0..4096}
do
    echo "$i" > inputs.txt
    ./asm < inputs.txt
done