.data
input_file_name:   .asciiz "//Users//ngophu//Desktop//BTL_CA//Test_3//input_matrix.txt"
output_file_name:  .asciiz "//Users//ngophu//Desktop//BTL_CA//Test_3//output_matrix.txt"
buffer:            .space 1024        # Bộ đệm để lưu nội dung tệp đầu vào
newline:           .asciiz "\n"       # Dấu xuống dòng
space:             .asciiz " "        # Dấu cách
output:            .asciiz "Ket qua tich chap la:\n"
N:                 .word 0            # Kích thước ma trận hình ảnh
M:                 .word 0            # Kích thước ma trận kernel
p:                 .word 0            # Padding
s:                 .word 0            # Stride
float_zero:        .float 0.0
float_ten:         .float 10.0
cham:              .byte '.'
tru:               .byte '-'
errorg: .asciiz "Error\n"
write_error_msg: .asciiz "Loi khi ghi file\n"
zero_char: .asciiz "0"
digit_array: .space 20  # Mảng lưu tạm các chữ số




#luu tru ma tran
matrananh:  .word 0:49   # kich thuoc toi da 7x7
matranpad: .word 0:225  # kich thuoc toi da 15x15
matranketqua: .word 0:225   # kich thuoc toi da 
matrankernel: .word 0:25   # kich thuoc toi da 5x5
#size
P_size:   .word 0    # Size sau khi padding
O_size:   .word 0    # Size cua output matrix

.text
.globl main
main:
    # for tich chap
    jal readInput
    convolution_begin:
    jal calculate_output_size  # Tinh toan kich thuoc ma tran sau khi padding
    jal paddingMatrix           # Thuc hien padding cho ma tran
    jal convolution   # Thuc hien phep tich chap
    jal printResult          # In ket qua
    jal write_output   #in ket qua ra file
    j exit                    # Thoat


readInput:
#mo file de doc file
li   $v0, 13           # System goi de mo file
la   $a0, input_file_name     # tai vao ten file
li   $a1, 0            # 0 la de doc file
li   $a2, 0            # 0 la quyn truy cap chi doc file
syscall
  
move $s0, $v0 
#1. doc file va gan vao buffer va 2.dong file
#1.
li   $v0, 14           # Goi system call de doc file
move $a0, $s0          # Truyen file descriptor (luu trong $s0) vao $a0
la   $a1, buffer       # Truyen dia chi cua buffer de luu du lieu vao $a1
li   $a2, 1024         # Truyen so byte toi da se doc (1024 byte) vao $a2
syscall                # Thuc hien system call
#2.
li   $v0, 16           # System call de dong file
move $a0, $s0          # File descriptor
syscall                # Thuc hien system call


# Xu ly dong dau tien (cac tham so)
la   $s0, buffer       # Pointer vao buffer

# Doc cac tham so N, M, p, s
jal  readInt
sw   $v0, N
jal  readInt
sw   $v0, M
jal  readInt
sw   $v0, p
jal  readInt
sw   $v0, s

# Bo qua dong tiep theo (newline)
jal  skip_the_line

# Doc ma tran hinh anh
lw   $s1, N            # Load N vao thanh ghi de su dung lam counter cho vong lap
la   $s2, matrananh # Load dia chi cua ma tran hinh anh
mul  $s3, $s1, $s1     # Tong so phan tu cua ma tran (N x N)
li   $s4, 0            # Khoi tao counter

readImageL: #L standforLoop
beq  $s4, $s3, readK # Thoat neu doc het cac phan tu
jal  readFloat
s.s  $f0, ($s2)       # Luu gia tri so thuc vao ma tran
addi $s2, $s2, 4      # Tang dia chi den phan tu tiep theo
addi $s4, $s4, 1      # Tang bien dem
j  readImageL

readK:
    # Bo qua dong tiep theo (newline)
    jal  skip_the_line
    # Doc ma tran kernel
    lw   $s1, M            # Load kich thuoc M cua kernel vao thanh ghi
    la   $s2, matrankernel # Load dia chi cua ma tran kernel
    mul  $s3, $s1, $s1     # Tinh tong so phan tu cua ma tran kernel (M x M)
    li   $s4, 0            # Khoi tao bien dem (counter)

readKernelL:
    beq  $s4, $s3, convolution_begin # Thoat neu da doc het phan tu
    jal  readFloat
    s.s  $f0, ($s2)       # Luu gia tri so thuc vao ma tran kernel
    addi $s2, $s2, 4      # Tang dia chi den phan tu tiep theo
    addi $s4, $s4, 1      # Tang bien dem
    j    readKernelL

# Doc cac so nguyen N, M, p, s
readInt:
    li   $v0, 0           # Khoi tao gia tri ban dau cho ket qua
readIntL:
    lb   $t0, ($s0)       # Doc ky tu hien tai tu bo dem
    
    # Kiem tra xem ky tu co phai so hay khong
    li   $t1, 48          # Tai gia tri '0'
    li   $t2, 57          # Tai gia tri '9'
    blt  $t0, $t1, not_digit   # Neu ky tu nho hon '0', khong phai so
    bgt  $t0, $t2, not_digit   # Neu ky tu lon hon '9', khong phai so

    # Chuyen doi ky tu thanh so va them vao ket qua
    subi $t0, $t0, 48      # Chuyen ky tu sang gia tri so
    mul  $v0, $v0, 10      # Nhan ket qua hien tai voi 10
    add  $v0, $v0, $t0     # Cong gia tri so moi vao ket qua
    addi $s0, $s0, 1       # Di chuyen den ky tu tiep theo
    j    readIntL          # Quay lai vong lap

not_digit:
    # Xac dinh cac ky tu dac biet (tab, khoang trang, xuong dong) va bo qua
    li   $t1, 32           # Ky tu khoang trang
    li   $t2, 10           # Ky tu xuong dong
    li   $t3, 9            # Ky tu tab
    li   $t4, 13           # Ky tu carriage return
    beq  $t0, $t1, skip  # Neu la khoang trang
    beq  $t0, $t2, skip  # Neu la xuong dong
    beq  $t0, $t3, skip  # Neu la tab
    beq  $t0, $t4, skip  # Neu la carriage return
    beq  $t0, 0, readIntok   # Neu la ky tu ket thuc chuoi (null terminator)
    j    readIntok          # Neu khong phai ky tu mong doi, thoat

skip:
    addi $s0, $s0, 1        # Bo qua ky tu dac biet
    jr   $ra                 # Quay lai ham goi

readIntok:
    jr   $ra                 # Tra ve ket qua

# Doc so thuc cho ma tran hinh anh va ma tran kernel
readFloat:
    li    $v0, 0          # Khoi tao phan nguyen cua so thuc
    li    $t7, 0          # Phan thap phan (chua su dung)
    li    $t8, 0          # So luong chu so thap phan (cung chua su dung)
    li    $t9, 0          # Co am, mac dinh la duong

    # Kiem tra dau tru
    lb    $t0, ($s0)      # Lay ky tu dau tien
    li    $t1, 45         # Ma ASCII cua dau '-'
    bne   $t0, $t1, readFloatL  # Neu khong phai dau '-', tiep tuc doc
    li    $t9, 1          # Danh dau so la am
    addi  $s0, $s0, 1     # Di chuyen qua dau '-' de bat dau doc so

readFloatL:
    lb    $t0, ($s0)      # Lay ky tu tiep theo tu chuoi dau vao

    # Kiem tra dau cham thap phan
    li    $t1, 46         # Ma ASCII cua dau '.'
    beq   $t0, $t1, readDecimal  # Neu la dau '.', chuyen qua xu ly phan thap phan

    # Kiem tra cac ky tu ket thuc so: khoang trang, newline, EOF, tab, hoac carriage return
    li    $t1, 32         # Ma ASCII cua khoang trang
    li    $t2, 10         # Ma ASCII cua newline
    li    $t3, 0          # Null terminator (EOF)
    li    $t4, 9          # Tab
    li    $t5, 13         # Carriage return

    beq   $t0, $t1, readFloatok
    beq   $t0, $t2, readFloatok
    beq   $t0, $t3, readFloatok
    beq   $t0, $t4, readFloatok
    beq   $t0, $t5, readFloatok

    # Kiem tra xem co phai la so khong
    li    $t1, 48         # Ma ASCII cua '0'
    li    $t2, 57         # Ma ASCII cua '9'
    blt   $t0, $t1, readFloatErr  # Neu nho hon '0'
    bgt   $t0, $t2, readFloatErr  # Neu lon hon '9'

    # Chuyen ky tu so tu ASCII sang gia tri so
    subi  $t0, $t0, 48    # Chuyen ky tu sang so
    mul   $v0, $v0, 10    # Nhan phan nguyen hien tai voi 10
    add   $v0, $v0, $t0   # Cong phan nguyen voi ky tu moi doc duoc

    addi  $s0, $s0, 1     # Di chuyen den ky tu tiep theo
    j     readFloatL    # Quay lai doc tiep
    
readDecimal:
    addi  $s0, $s0, 1 #bo qua decimal point
    
readDecimalL:
    lb    $t0, ($s0)      # Load character tu chuoi dau vao
    
    # Kiem tra ket thuc so (space, newline, EOF, tab, carriage return)
    li    $t1, 32         # Ma ASCII cua khoang trang
    li    $t2, 10         # Ma ASCII cua newline
    li    $t3, 0          # Null terminator (EOF)
    li    $t4, 9          # Ma ASCII cua tab
    li    $t5, 13         # Ma ASCII cua carriage return

    beq   $t0, $t1, readFloatok  # Space
    beq   $t0, $t2, readFloatok  # Newline
    beq   $t0, $t3, readFloatok  # Null/EOF
    beq   $t0, $t4, readFloatok  # Tab
    beq   $t0, $t5, readFloatok  # Carriage return
    
    # Kiem tra xem co phai la so khong ('0' den '9')
    li    $t1, 48         # ASCII cua '0'
    li    $t2, 57         # ASCII cua '9'

    # So sanh ky tu doc duoc voi '0' va '9'
    slt   $t3, $t0, $t1   # Neu $t0 < '0', $t3 = 1
    slt   $t4, $t2, $t0   # Neu $t0 > '9', $t4 = 1
    or    $t3, $t3, $t4   # Neu ky tu khong phai so, $t3 = 1
    bnez  $t3, readFloatErr  # Neu $t3 != 0, co loi (khong phai so hop le)

    # Chuyen ky tu so tu ASCII sang gia tri so
    subi  $t0, $t0, 48        # Chuyen ky tu sang so
    
    # Tinh toan gia tri phan thap phan
    mul   $t7, $t7, 10        # Nhan phan thap phan hien tai voi 10
    add   $t7, $t7, $t0       # Cong them chu so moi vao phan thap phan

    # Tang so luong chu so thap phan
    addi  $t8, $t8, 1         # Tang so chu so thap phan

    # Di chuyen den ky tu tiep theo
    addi  $s0, $s0, 1         # Tien den ky tu tiep theo
    j     readDecimalL     # Tiep tuc vong lap

readFloatok:
# Chuyen phan nguyen thanh so thuc
    mtc1  $v0, $f0        # Chuyen gia tri phan nguyen vao thanh ghi so thuc
    cvt.s.w $f0, $f0      # Chuyen doi thanh so thuc (float)
    
    # Neu khong co phan thap phan, bo qua
    beqz  $t8, checkNeg  # Neu so thap phan = 0, nhay den kiem tra am

    # Chuyen phan thap phan thanh so thuc
    mtc1  $t7, $f1        # Chuyen gia tri phan thap phan vao thanh ghi so thuc
    cvt.s.w $f1, $f1      # Chuyen doi thanh so thuc (float)
    
    # Duyet tu 10^0 den 10^so_chu_so_thap_phan de tinh toan
    li    $t0, 1          # Bat dau voi gia tri 1 (10^0)
    li    $t1, 0          # Khoi tao bien dem cho so luong chu so thap phan
    
DecimalDiviL:
    beq   $t1, $t8, AppDecimal      # Neu du so chu so thap phan, tiep tuc xu ly phan thap phan
    mul   $t0, $t0, 10              # Nhan divisor voi 10 (gioi han do chinh xac cua phan thap phan)
    addi  $t1, $t1, 1               # Tang bo dem so chu so thap phan
    j     DecimalDiviL              # Tiep tuc vong lap

AppDecimal:
    # luu gia tri divisor vao mot thanh ghi tam thoi
    move  $t5, $t0                  # Luu divisor vao $t5 de su dung trong buoc chia sau
    mtc1  $t5, $f2                  # Dua divisor vao thanh ghi so thuc
    cvt.s.w $f2, $f2                # Chuyen divisor thanh so thuc (float)
    
    #  Thuc hien phep chia 
    div.s $f1, $f1, $f2             # Chia phan thap phan cho 10^decimal_places

    # Thuc hien phep toan cong vao phan nguyen
    add.s $f0, $f0, $f1             # Cong ket qua vao phan nguyen (cap nhat so thuc)

checkNeg:
    # Kiem tra neu can doi dau am
    beqz  $t9, skip_delimiter       # Neu khong co dau am, bo qua
    neg.s $f0, $f0                  # Doi dau phan thuc

skip_delimiter:
    # Bo qua cac ky tu phan cach (space, newline, v.v.)
    lb    $t0, ($s0)                # Doc ky tu tiep theo
    beqz  $t0, readFloatandReturn    # Neu EOF, thoat
    addi  $s0, $s0, 1               # Di chuyen con tro toi ky tu tiep theo

readFloatandReturn:
    jr    $ra                       # Tro lai sau khi hoan thanh

readFloatErr:
    # Xu ly loi neu co su co
    j     readFloatok           # Quay lai xu ly khi co loi

skip_the_line:
    lb   $t0, ($s0)       # Load character
    beq  $t0, 10, skip_line_ok  # Newline found
    beq  $t0, 0, skip_line_ok   # End of string
    addi $s0, $s0, 1      # Next character
    j    skip_the_line       # Quay lai vong lap kiem tra ky tu tiep theo

process_char:
    # Thu thuc hanh dong voi ky tu chu cai tai day (theo yeu cau)
    addi $s0, $s0, 1         # Di chuyen con tro toi ky tu tiep theo
    j    skip_the_line       # Quay lai vong lap kiem tra ky tu tiep theo

process_digit:
    # Thu thuc hanh dong voi ky tu so tai day (theo yeu cau)
    addi $s0, $s0, 1         # Di chuyen con tro toi ky tu tiep theo
    j    skip_the_line       # Quay lai vong lap kiem tra ky tu tiep theo

skip_line_ok:
    addi $s0, $s0, 1         # Bo qua newline
    jr   $ra                  # Tro lai

    
calculate_output_size:
    # Kiểm tra giá trị N (3 ≤ N ≤ 7)
    lw   $t0, N           # Tải kích thước của hình ảnh (N)
    blt  $t0, 3, file_error   # Nếu N < 3 thì nhảy tới file_error
    bgt  $t0, 7, file_error   # Nếu N > 7 thì nhảy tới file_error

    # Kiểm tra giá trị M (2 ≤ M ≤ 4)
    lw   $t1, M           # Tải kích thước của kernel (M)
    blt  $t1, 2, file_error   # Nếu M < 2 thì nhảy tới file_error
    bgt  $t1, 4, file_error   # Nếu M > 4 thì nhảy tới file_error

    # Kiểm tra giá trị p (0 ≤ p ≤ 4)
    lw   $t2, p           # Tải giá trị padding (p)
    blt  $t2, 0, file_error   # Nếu p < 0 thì nhảy tới file_error
    bgt  $t2, 4, file_error   # Nếu p > 4 thì nhảy tới file_error

    # Kiểm tra giá trị s (1 ≤ s ≤ 3)
    lw   $t3, s           # Tải giá trị stride (s)
    blt  $t3, 1, file_error   # Nếu s < 1 thì nhảy tới file_error
    bgt  $t3, 3, file_error   # Nếu s > 3 thì nhảy tới file_error

    # Tinh kich thuoc duoc dem = N + 2p
    lw   $t0, N           # Tai kich thuoc cua hinh anh
    lw   $t1, p           # Tai gia tri padding
    mul  $t2, $t1, 2      # Tinh 2p (2 * padding)
    add  $t2, $t0, $t2    # N + 2p
    sw   $t2, P_size      # Luu ket qua vao P_size (kich thuoc dem)
    

    # Luu gia tri N + 2p vao thanh ghi t5
    move $t5, $t2         # Luu ket qua (N + 2p) vao $t5

    # Tinh kich thuoc dau ra = (N + 2p - M) / s + 1
    lw   $t3, M           # Tai kich thuoc kernel
    # Kiểm tra điều kiện M < (N + 2p)
    blt  $t5, $t3, file_error  # Nếu M lớn hơn (N + 2p), nhảy tới file_error
    sub  $t2, $t5, $t3    # (N + 2p - M)
    
    # Luu gia tri (N + 2p - M) vao thanh ghi t6
    move $t6, $t2         # Luu ket qua (N + 2p - M) vao $t6

    lw   $t4, s           # Tai stride
    div  $t2, $t4         # Chia (N + 2p - M) cho stride
    #mfhi $t8              # Lay phan du sau phep chia

    # Kiem tra xem co phan du hay khong
    #bnez $t8, file_error  # Neu co phan du, jump toi exit_program

    mflo $t2              # Lay thuong (quotient) sau phep chia

    # Luu gia tri thuong so vao thanh ghi t7
    move $t7, $t2         # Luu ket qua thuong so vao $t7

    addi $t2, $t2, 1      # Cong 1 vao ket qua (kich thuoc dau ra cuoi cung)
    sw   $t2, O_size      # Luu ket qua vao O_size (kich thuoc dau ra)

    jr   $ra              # Quay lai chuong trinh goi
    

# Pad the input matrix with zeros
paddingMatrix:
    # Lay kich thuoc ma tran goc va cac gia tri lien quan
    lw   $t0, N           # Kich thuoc ma tran goc
    lw   $t1, p           # Kich thuoc padding
    lw   $t2, P_size # Kich thuoc ma tran sau khi padding
    
    # Tinh toan tong so phan tu trong ma tran sau khi padding
    mul  $t4, $t2, $t2    # Tong so phan tu trong ma tran padded (t2 * t2)
    li   $t5, 0           # Khoi tao bo dem phan tu (t5)

    # Lam sach ma tran padded (set tat ca phan tu ve 0)
    la   $t3, matranpad # Dia chi ma tran padded
    l.s  $f0, float_zero   # Dat gia tri 0 vao thanh ghi float

clearLoop:
    beq  $t5, $t4, copy_ori  # Neu bo dem bang tong so phan tu, chuyen sang buoc sao chep
    s.s   $f0, ($t3)       # Gan gia tri 0 vao ma tran padded
    addi $t3, $t3, 4       # Di chuyen den phan tu tiep theo
    addi $t5, $t5, 1       # Tang bo dem
    j    clearLoop    # Tiep tuc vong lap
    
copy_ori:
    #  Luu gia tri cua (padded_size - N) vao thanh ghi $t7 de tinh toan offset
    mul  $t5, $t1, $t2    # padding * padded_size
    mul  $t5, $t5, 4      # Chuyen sang don vi byte
    # Tinh toan offset dong ban dau
    la   $t3, matrananh # Ma tran nguon (hinh anh goc)
    la   $t4, matranpad # Ma tran dich (ma tran da padding)
    
    add  $t4, $t4, $t5    # Di chuyen den vi tri dung cua dong trong ma tran dich
    
    #  Tinh toan offset cot (padding * 4 bytes)
    mul  $t5, $t1, 4      # padding * 4 bytes
    add  $t4, $t4, $t5    # Di chuyen den vi tri dung cua cot trong ma tran dich

    li   $t5, 0           # Bo dem dong

copyRowL:
    beq  $t5, $t0, padok  # Neu da sao chep du dong, ket thuc
    li   $t6, 0           # Bo dem cot

copyColL:
    beq  $t6, $t0, padNextrow  # Neu da sao chep du cot, chuyen sang dong tiep theo
    
    #  Luu gia tri cua phan tu trong ma tran nguon vao thanh ghi float ($f0)
    l.s  $f0, ($t3)       # Lay phan tu tu ma tran nguon
    s.s  $f0, ($t4)       # Sao chep phan tu vao ma tran dich
    
    addi $t3, $t3, 4      # Di chuyen den phan tu tiep theo trong ma tran nguon
    addi $t4, $t4, 4      # Di chuyen den phan tu tiep theo trong ma tran dich
    addi $t6, $t6, 1      # Tang bo dem cot
    j    copyColL         # Tiep tuc sao chep cot

padNextrow:
    #  Tinh toan offset cua dong tiep theo (tinh padding cho dong tiep theo)
    sub  $t7, $t2, $t0    # Tinh toan so dong can padding (padded_size - N)
    mul  $t7, $t7, 4      # Chuyen sang don vi byte
    add  $t4, $t4, $t7    # Di chuyen den vi tri dung cua dong tiep theo trong ma tran dich

    addi $t5, $t5, 1      # Tang bo dem dong
    j    copyRowL # Tiep tuc sao chep dong tiep theo

padok:
    jr   $ra              # Tro lai


# Thuc hien phep tich chap
# Thuc hien phep tich chap
convolution:
    # Luu dia chi tro ve va khung stack
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $fp, 4($sp)
    
    # Nap cac tham so: kich thuoc ma tran, kernel, stride
    lw   $s0, P_size      # Kich thuoc ma tran da padding
    lw   $s1, M           # Kich thuoc kernel
    lw   $s2, s           # Stride
    lw   $s3, O_size      # Kich thuoc ma tran ket qua
    
    # Nap dia chi cac ma tran
    la   $s4, matranpad 
    la   $s5, matrankernel 
    la   $s6, matranketqua 
    
    # Khoi tao bo dem dong ket qua
    li   $t0, 0           

convRowL:
    beq  $t0, $s3, convok  # Kiem tra dong ket qua cuoi cung
    li   $t1, 0           # Khoi tao bo dem cot ket qua
    
convColL:
    beq  $t1, $s3, convNextR  # Kiem tra cot ket qua cuoi cung
    
    # Khoi tao tong = 0
    l.s  $f12, float_zero 
    li   $t2, 0           # Bo dem dong kernel
    
convKernelR:
    beq  $t2, $s1, convStore  # Kiem tra dong kernel cuoi cung
    li   $t3, 0           # Bo dem cot kernel
    
convKernelC:
    beq  $t3, $s1, convNextKernelR  # Kiem tra cot kernel cuoi cung
    
    # Tinh toan vi tri trong ma tran da padding
    mul  $t4, $t0, $s2    # (dong * stride)
    mul  $t5, $t1, $s2    # (cot * stride)
    
    add  $t6, $t4, $t2    # (dong * stride) + kernel_row
    mul  $t6, $t6, $s0    # Nhan voi chieu rong ma tran da padding
    add  $t7, $t5, $t3    # (cot * stride) + kernel_col
    add  $t6, $t6, $t7    # Vi tri cuoi cung
    
    # Tinh toan vi tri kernel
    mul  $t7, $t2, $s1    # kernel_row * kernel_width
    add  $t7, $t7, $t3    # kernel_row + kernel_col
    
    # Chuyen doi dia chi sang byte
    mul  $t6, $t6, 4      
    mul  $t7, $t7, 4      
    
    # Them dia chi goc
    add  $t6, $t6, $s4    # Dia chi goc ma tran da padding
    add  $t7, $t7, $s5    # Dia chi goc kernel
    
    # Lay gia tri va thuc hien phep tinh
    l.s  $f1, ($t6)       # Gia tri tu ma tran da padding
    l.s  $f2, ($t7)       # Gia tri tu kernel
    mul.s $f1, $f1, $f2   # Nhan hai gia tri
    add.s $f12, $f12, $f1 # Cong vao tong
    
    addi $t3, $t3, 1      # Tang bo dem cot kernel
    j    convKernelC
    
convNextKernelR:
    addi $t2, $t2, 1      # Tang bo dem dong kernel
    j    convKernelR
    
convStore:
    # Luu ket qua vao ma tran ket qua
    mul  $t4, $t0, $s3    # (dong * width)
    add  $t4, $t4, $t1    # (dong * width) + cot
    mul  $t4, $t4, 4      # Chuyen sang byte
    add  $t4, $t4, $s6    # Them dia chi goc ma tran ket qua
    s.s  $f12, ($t4)      # Luu gia tri
    
    addi $t1, $t1, 1      # Tang bo dem cot ket qua
    j    convColL
    
convNextR:
    addi $t0, $t0, 1      # Tang bo dem dong ket qua
    j    convRowL
    
convok:
    # Khoi phuc dia chi tro ve
    lw   $ra, 0($sp)
    lw   $fp, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

printResult:
    # Print header
    li   $v0, 4           # Syscall: print string
    la   $a0, output      # Chuỗi tiêu đề
    syscall
    
    # Initialize counters
    lw   $t0, O_size      # Matrix size (số hàng hoặc cột của ma trận vuông)
    li   $t1, 0           # Row counter
    la   $t2, matranketqua # Base address của ma trận kết quả
    
printRowL:
    beq  $t1, $t0, printok # Nếu đã in hết hàng, kết thúc
    li   $t3, 0            # Column counter
    
printColL:
    beq  $t3, $t0, printNewline # Nếu đã in hết cột, xuống dòng
    
    # Load số từ mảng
    l.s   $f1, ($t2)       # Load giá trị float từ địa chỉ của ma trận
    
    # Nhân với 10000.0 để giữ 4 chữ số thập phân
    li    $t5, 10000       # Load 10000 vào thanh ghi số nguyên
    mtc1  $t5, $f2         # Move số nguyên từ $t5 sang thanh ghi dấu phẩy động $f2
    cvt.s.w $f2, $f2       # Chuyển đổi số nguyên trong $f2 thành số thực (float)
    mul.s $f1, $f1, $f2    # $f1 = $f1 * 10000.0
    
    # Chuyển về số nguyên
    trunc.w.s $f3, $f1     # Làm tròn xuống, lưu vào $f3 (float)
    mfc1   $t4, $f3        # Move từ thanh ghi float sang integer ($t4)
    
    # Tách phần nguyên và phần lẻ
    div    $t5, $t4, 10000 # $t5 = phần nguyên (chia lấy nguyên)
    mul    $t7, $t5, 10000 # $t7 = phần nguyên * 10000 (phục hồi)
    sub    $t6, $t4, $t7   # $t6 = phần thập phân = số ban đầu - phần nguyên * 10000
    abs    $t6, $t6        # Lấy giá trị tuyệt đối của phần thập phân
    
    # Print phần nguyên
    li   $v0, 1            # Syscall: print integer
    move $a0, $t5          # Đưa phần nguyên vào $a0
    syscall
    
    # Print dấu chấm
    li   $v0, 11           # Syscall: print character
    li   $a0, '.'          # In dấu '.'
    syscall
    
    # Print phần thập phân (đảm bảo đủ 4 chữ số)
    li   $t7, 1000         # Ngưỡng kiểm tra số chữ số
    blt  $t6, $t7, padZero # Nếu phần thập phân < 1000, in thêm số 0

    # In phần thập phân trực tiếp
    li   $v0, 1            # Syscall: print integer
    move $a0, $t6          # Đưa phần thập phân vào $a0
    syscall
    j    printSpace        # Nhảy tới bước in dấu cách
    
padZero:
    # In các số 0 trước phần thập phân nếu thiếu
    li   $v0, 11           # Syscall: print character
    li   $a0, '0'
    syscall
    blt  $t6, 100, padZero2

padZero2:
    li   $v0, 11
    li   $a0, '0'
    syscall
    blt  $t6, 10, padZero3

padZero3:
    li   $v0, 11
    li   $a0, '0'
    syscall

    # Print phần thập phân
    li   $v0, 1
    move $a0, $t6
    syscall

printSpace:
    # Print dấu cách
    li   $v0, 4
    la   $a0, space
    syscall

    # Di chuyển đến phần tử tiếp theo
    addi $t2, $t2, 4       # Tăng địa chỉ (4 byte mỗi số float)
    addi $t3, $t3, 1       # Tăng cột
    j    printColL         # Lặp lại cho cột tiếp theo
    
printNewline:
    li   $v0, 4            # Syscall: print string
    la   $a0, newline      # Chuỗi xuống dòng
    syscall
    
    addi $t1, $t1, 1       # Tăng hàng
    j    printRowL         # Lặp lại cho hàng tiếp theo
    
printok:
    jr   $ra               # Trả về


write_output:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $s5, 0($sp)
    
    # Mở file
    li $v0, 13
    la $a0, output_file_name
    li $a1, 1
    li $a2, 0x1FF
    syscall
    move $s0, $v0
    
    # Check lỗi
    bltz $s0, write_error
    
    lw $s1, O_size
    
    li $s2, 0           # row counter
row_loop:
    beq $s2, $s1, write_done
    
    li $s3, 0           # column counter
col_loop:
    beq $s3, $s1, row_next
    
    # Tính offset và lấy giá trị float
    mul $t0, $s2, $s1
    add $t0, $t0, $s3
    sll $t0, $t0, 2
    la $t1, matranketqua
    add $t1, $t1, $t0
    l.s $f12, ($t1)
    
    # Chuẩn bị buffer
    la $s4, buffer
    move $s5, $s4
    
    # Kiểm tra số âm
    l.s $f0, float_zero
    c.lt.s $f12, $f0
    bc1f not_negative
    
    # Thêm dấu trừ nếu là số âm
    li $t4, 45          # ASCII for '-'
    sb $t4, ($s4)
    addi $s4, $s4, 1
    abs.s $f12, $f12    # Lấy giá trị tuyệt đối
    
not_negative:
    # Chuyển phần nguyên thành integer
    cvt.w.s $f0, $f12
    mfc1 $t2, $f0
    
    # In phần nguyên
    move $t3, $t2       # Copy giá trị để không làm mất
    li $t4, 10
    
    # Kiểm tra nếu là 0
    bnez $t3, store_digits
    li $t5, 48          # ASCII for '0'
    sb $t5, ($s4)
    addi $s4, $s4, 1
    j add_decimal

store_digits:
    la $t7, digit_array    # Base address của mảng
    li $t6, 0              # Đếm số chữ số
    
digit_to_array:
    div $t3, $t4           # Chia cho 10
    mfhi $t5               # Lấy phần dư (chữ số)
    addi $t5, $t5, 48      # Chuyển thành ASCII
    sb $t5, ($t7)          # Lưu vào mảng
    addi $t7, $t7, 1       # Tăng địa chỉ mảng
    addi $t6, $t6, 1       # Tăng số lượng chữ số
    mflo $t3               # Lấy phần nguyên
    bnez $t3, digit_to_array  # Tiếp tục nếu còn chữ số
    
    # In các chữ số theo thứ tự từ trái sang phải
print_digits:
    addi $t7, $t7, -1     # Lùi con trỏ mảng
    lb $t5, ($t7)         # Lấy chữ số từ mảng
    sb $t5, ($s4)         # Lưu vào buffer
    addi $s4, $s4, 1      # Tăng con trỏ buffer
    addi $t6, $t6, -1     # Giảm số chữ số
    bnez $t6, print_digits # Tiếp tục nếu còn chữ số
    
add_decimal:
    # Thêm dấu chấm
    li $t4, 46          # ASCII for '.'
    sb $t4, ($s4)
    addi $s4, $s4, 1
    
    # Lấy phần thập phân
    cvt.w.s $f0, $f12
    cvt.s.w $f0, $f0
    sub.s $f0, $f12, $f0
    abs.s $f0, $f0
    
    # In 4 chữ số thập phân
    l.s $f2, float_ten
    li $t4, 4
decimal_loop:
    mul.s $f0, $f0, $f2
    cvt.w.s $f3, $f0
    mfc1 $t5, $f3
    addi $t5, $t5, 48   # Chuyển thành ASCII
    sb $t5, ($s4)
    addi $s4, $s4, 1
    
    cvt.s.w $f3, $f3
    sub.s $f0, $f0, $f3
    
    addi $t4, $t4, -1
    bnez $t4, decimal_loop
    
    # Thêm khoảng trắng
    li $t4, 32          # ASCII for space
    sb $t4, ($s4)
    addi $s4, $s4, 1
    
    # Ghi vào file
    li $v0, 15
    move $a0, $s0
    move $a1, $s5
    sub $a2, $s4, $s5
    syscall
    
    addi $s3, $s3, 1
    j col_loop
    
row_next:
    # Thêm newline
    #li $v0, 15
    #move $a0, $s0
    #la $a1, newline
    #li $a2, 1
    #syscall
    
    addi $s2, $s2, 1
    j row_loop
    
write_error:
    li $v0, 4
    la $a0, write_error_msg
    syscall
    j write_exit
    
write_done:
    # Đóng file
    li $v0, 16
    move $a0, $s0
    syscall
    
write_exit:
    lw $ra, 24($sp)
    lw $s0, 20($sp)
    lw $s1, 16($sp)
    lw $s2, 12($sp)
    lw $s3, 8($sp)
    lw $s4, 4($sp)
    lw $s5, 0($sp)
    addi $sp, $sp, 28
    jr $ra

# Error handler and exit
file_error:
    li   $v0, 4           # System call for print string
    la   $a0, errorg  # Load error message
    syscall
exit:
    li   $v0, 10
    syscall

 