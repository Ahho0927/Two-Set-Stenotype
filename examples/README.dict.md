# 두벌식 속기 사용법

속기 키보드는 기본적으로 하나의 stroke 당 하나의 입력을 전제로 한다.\
stroke는 하나의 키 조합을 의미하며,키보드의 모든 키가 떼진 상태에서 최초의 키가 눌러집과 동시에 stroke가 시작되며,그 후 모든 키가 떼지는 순간 stroke는 종료된다.\
한 stroke 동안 한 번 이상 눌린 모든 키의 조합을 chord라고 한다. chord를 표현하는 방법은 기본적으로 영숫자를 사용하며,예외적으로 `shift`와 `spacebar`는 `^`, `_`를 사용한다.\

``` txt
R = ㄱ    K = ㅏ
S = ㄴ    O = ㅐ
E = ㄷ    I = ㅑ
F = ㄹ    J = ㅓ
A = ㅁ    P = ㅔ
Q = ㅂ    U = ㅕ
T = ㅅ    H = ㅗ
D = ㅇ    Y = ㅛ
W = ㅈ    N = ㅜ
C = ㅊ    B = ㅠ
Z = ㅋ    M = ㅡ
X = ㅌ    L = ㅣ
V = ㅍ
G = ㅎ
```

## 한글 조합법

한 stroke 당 최소 음절 하나를 기본 원칙으로 한다. 즉, 한 stroke 당 한 글자이다.

### 받침이 없는 경우

기본적인 한글 조합법을 따른다.

``` txt
RK = 가
DO = 애
```

이중모음도 조합하고자 하는 모음을 모두 눌러 조합 가능하다.
단, `ㅒ`, `ㅖ`는 별도의 조합법을 사용한다.\
`ㅑ`+`ㅐ` -> `ㅒ`, `ㅑ`+`ㅔ` -> `ㅖ`.

``` txt
DHK = 와
RNL = 귀
WIO = 쟤
DIP = 예
```

된소리는 `shift` 키를 눌러서 입력할 수 있다. 단, `shift` 키는 초성에만 적용된다.

``` txt
^RK = 까
^EO = 때
^TJ = 써
```

### 받침이 있는 경우

#### 두 자음이 같은 경우

초성과 종성이 같은 글자를 입력하기 위해서는 특수키 `;`를 사용한다.

``` txt
RK; = 각
EM; = 듣
TH; = 솟
```

단, 이 때 `shift` 키를 누른다고 해서 받침까지 된소리가 되지는 않는다.

``` txt
^RK; = 깍
^TL; = 씻
```

#### 두 자음이 다른 경우

초성과 다른 글자를 받침에 넣기 위해서는 두 개의 자음을 한 stroke에 모두 입력해야 한다. 하지만 이 경우 두 자음 중 어느 자음을 받침에 넣을지가 불분명하다. 이 때 사용하는 것이 `;`이다.

`;` 없이 자음을 두 개 입력할 경우, ㄱㄴㄷ순으로 정렬 시 상대적으로 뒤에 있는 자음이 받침으로 들어간다.

``` txt
RKS = 간
EMF = 들
WHG = 좋
^EJR; = 떡
```

여기에 `;`를 추가적으로 입력할 경우 두 자음의 위치가 서로 바뀐다.

``` txt
SKR; = 낙SKR = 간
WJR; = 적WJR = 겆
GUS; = 현GUS = 녛
```

##### `ㄲ`, `ㅆ`의 경우

두벌식 속기 키보드에서는 `ㄲ`, `ㅆ`을 각각 별도의 키 `'`와 `/`로 지정하여 활용도를 높였다.

``` txt
QK' = 밖
RK/ = 갔
```

##### 받침 전용 글자

한글에는 받침에서만 쓸 수 있는 글자가 있다.
`ㄳ`, `ㄵ`, `ㄶ`, `ㄺ`, `ㄻ`, `ㄼ`, `ㄽ`, `ㄾ`, `ㄿ`, `ㅀ`, `ㅄ`인데, 이 입력을 가능케하기 위해서 `ㄲ`과 `ㅆ` 키가 활용된다.\
`ㄲ` + `ㅅ`/`ㅈ`/`ㅎ`/`ㅂ` = `ㄳ`/`ㄵ`/`ㄶ`/`ㅄ`\
`ㅆ` + `ㄱ`/`ㅁ`/`ㅂ`/`ㅅ`/`ㅌ`/`ㅍ`/`ㅎ` = `ㄺ`/`ㄻ`/`ㄼ`/`ㄽ`/`ㄾ`/`ㄿ`/`ㅀ`
받침에 어떤 자음을 넣어야 할지를 잘 고민하고 입력해야 한다.

``` txt
EKR;/ = 닭
TKA;/ = 삶
SJQ/ = 넓
DLG/ = 잃
RKQ' = 값
DJQ;' = 없
AHT' = 몫
DKW' = 앉
WKG' = 잖
```

## 약어 목록

### 접사

#### 기본 접사

``` txt
K = "가 "
' = "게 "
R = "고 "
RW' = "고자 "
W' = "까지 "
R' = "께 "
'T = "께서 "
A' = "끔 "
S = "는 "
SE' = "는데 "
SW' = "는지 "
S' = "니까 "
ER; = "다고 "
ES; = "다는 "
EA; = "다며 "
EAS; = "다면 "
E = "도 "
EFR = "도록 "
FE' = "ㄹ 때 "
FT' = "ㄹ 수 "
FR = "라고 "
FS = "라는 "
FE = "라도 "
FA = "라며 "
FAS = "라면 "
FT = "라서 "
H = "로 "
H/ = "로써 "
A; = "만 "
AZ = "만큼 "
A = "며 "
AS = "면 "
AT = "면서 "
Q' = "밖에 "
QE = "보다 "
QX = "부터 "
Q = "뿐 "
QNMF = "뿐 아니라 "
QANMF = "뿐만 아니라 "
I = "야 "
DAFI = "야말로 "
Y = "요 "
DF = "으로 "/"므로 "
DFT = "으로서 "/"므로서 "
DF/ = "으로써 "/"므로써 "
DS = "은 "
ML = "의 "
T = "서 "
^T = "써 "
R/ = "씩 "
W = "지 "
WA = "지만 "
CF = "처럼 "
```

#### 에~ 조사

``` txt
OP = "에 "
OPS = "에는 "
OPA = "에만 "
OPT = "에서 "
OPE = "에도 "
OPR = "에게 "
OPZFS = "에 관련"
OPZ = "에 관하"
OPZD = "에 관하여 "
OPZS = "에 관한 "
OPZF = "에 관할 "
OPZGD = "에 관해 "
OPZT = "에 관해서 "
OPX = "에 대하"
OPXD = "에 대하여 "
OPXS = "에 대한 "
OPXF = "에 대할 "
OPXG = "에 대해 "
OPXT = "에 대해서 "
OPF = "에 따라 "
OPFT = "에 따라서 "
OPFR = "에 따르고 "
OPFA = "에 따르며 "
OPFAS = "에 따르면 "
OPFS = "에 따른 "
OPQ = "에 비하"
OPQD = "에 비하여 "
OPQS = "에 비한 "
OPQF = "에 비할 "
OPQFT = "에 비할 수 "
OPQZ = "에 비해 "
PMLG = "에 의하"
PMLGAS = "에 의하면 "
PMLGD = "에 의하여 "
PMLGS = "에 의한 "
PMLGF = "에 의할 "
PMLGFE = "에 의할 때 "
PMLGFT = "에 의할 수 "
PMLGFW = "에 의할지 "
PMLGZ = "에 의해 "
PMLGT = "에 의해서 "
```

#### 와/과~ 조사

``` txt
HK = "과 "/"와 "
HKL = "과 관련"/"와 관련"
HKLS = "과 관련한 "/"와 관련한 "
HKLG = "과 관련해 "/"와 관련해 "
HKLGT = "과 관련해서 "/"와 관련해서 "
HJK = "과 같"/"와 같"
HJK' = "과 같게 "/"와 같게 "
HJKR = "과 같고 "/"와 같고 "
HJKE = "과 같다"/"와 같다"
HJKER = "과 같다고 "/"와 같다고 "
HJKES = "과 같다는 "/"와 같다는 "
HJKEA = "과 같다며 "/"와 같다며 "
HJKEAS = "과 같다면 "/"와 같다면 "
HJKTEW = "과 같습니다. "/"와 같습니다. "
HJK^TEW = "과 같습니까? "/"와 같습니까? "
HJKTEWA = "과 같습니다만 "/"와 같습니다만 "
HJKD = "과 같아"/"와 같아"
HJKDE = "과 같아도 "/"와 같아도 "
HJKDT = "과 같아서 "/"와 같아서 "
HJKA = "과 같으며 "/"와 같으며 "
HJKAS = "과 같으면 "/"와 같으면 "
HJKAT = "과 같으면서 "/"와 같으면서 "
HJKDF = "과 같으므로 "/"와 같으므로 "
HJKDFT = "과 같음으로써 "/"와 같음으로써 "
HJKDS = "과 같은 "/"와 같은 "
HJKF = "과 같을 "/"와 같을 "
HJKFE = "과 같을 때 "/"와 같을 때 "
HJKFT = "과 같을 수 "/"와 같을 수 "
HJKF' = "과 같을까 "/"와 같을까 "
HJKFW = "과 같을지 "/"와 같을지 "
HJKL = "과 같이 "/"와 같이 "
HJKW = "과 같지 "/"와 같지 "
```

#### ㅂ니다 시리즈

``` txt
QWE = "ㅂ니다. "
^QWE = "ㅂ니까? "
QWEA = "ㅂ니다만 "
TQWE = "ㅂ시다. "
TEW = "습니다. "
^TEW = "습니까? "
TEWA = "습니다만 "
/TEW = "ㅆ습니다. "
/^TEW = "ㅆ습니까? "
/TEWA = "ㅆ습니다만 "
REW = "겠습니다. "
^REW = "겠습니까? "
REWA = "겠습니다만 "
```

#### 을~ 접사

``` txt
F = "을 "/"를 "
NML = "을 위하"/"를 위하"
NMLR = "을 위하고 "/"를 위하고 "
NMLA = "을 위하며 "/"를 위하며 "
NMLD = "을 위하여 "/"를 위하여 "
NMLS = "을 위한 "/"를 위한 "
NMLG = "을 위해 "/"를 위해 "
NMLGT = "을 위해서 "/"를 위해서 "
MH = "을 통 "/"를 통 "
MH' = "을 통하게 "/"를 통하게 "
MHR = "을 통하고 "/"를 통하고 "
MHA = "을 통하며 "/"를 통하며 "
MHAS = "을 통하면 "/"를 통하면 "
MHAT = "을 통하면서 "/"를 통하면서 "
MHD = "을 통하여 "/"를 통하여 "
MHW = "을 통하지 "/"를 통하지 "
MHS = "을 통한 "/"를 통한 "
MHF = "을 통할 "/"를 통할 "
MHFE = "을 통할 때 "/"를 통할 때 "
MHFT = "을 통할 수 "/"를 통할 수 "
MHFW = "을 통할지 "/"를 통할지 "
MHG = "을 통해 "/"를 통해 "
MHGT = "을 통해서 "/"를 통해서 "
```

#### 이 접사

``` txt
L = "이 "
KL;E = "이다"
KL;F = "이라"
KL;FR = "이라고 "
KL;FS = "이라는 "
KL;FE = "이라도 "
KL;FA = "이라며 "
KL;FT = "이라서 "
KL;A = "이며 "
KL;AS = "이면 "
KL;AT = "이면서 "
KL;DF = "이므로 "
KL;DFT = "이므로서 "
KL;R = "이고 "
KL;W = "이지 "
KL;WA = "이지만 "
LQWE = "입니다. "
L^QWE = "입니까? "
LQWEA = "입니다만 "
LTEW = "이십니다. "
L^TEW = "이십니까? "
LTEWA = "이십니다만 "
L/ = "이었"
L/TEW = "이었습니다. "
L/^TEW = "이었습니까? "
/LTEWA = "이었습니다만 "
LREW = "이겠습니다. "
L^REW = "이겠습니까? "
LREWA = "이겠습니다만 "
```

#### 기 위하~ 접사

``` txt
NKL = "기 위하"
NKLR = "기 위하고 "
NKLA = "기 위하며 "
NKLD = "기 위하여 "
NKLS = "기 위한 "
NKLG = "기 위해 "
NKLGT = "기 위해서 "
```

### 용언

``` txt
G' = "하게 "
GREW = "하겠습니다. "
GREWA = "하겠습니다만 "
G^REW = "하겠습니까? "
GR = "하고 "
GRW = "하고자 "
GS = "하는 "
GSE' = "하는데 "
GE = "하다 "
GER = "하다고 "
GES = "하다는 "
GEAS = "하다면 "
GEFR = "하도록 "
GA = "하며 "
GAS = "하면 "
GAT = "하면서 "
GDF = "하므로 "
GD = "하여 "
GDE = "하여도 "
GDT = "하여서 "
GW = "하지 "
GWA = "하지만 "
GEWQ = "합니다. "
GEWQA = "합니다만 "
G^EWQ = "합니까? "
GF = "할 "
GF' = "할까 "
GFW = "할지 "
GFE = "할 때 "
GFT = "할 수 "
GT = "해서 "
G/ = "했"
G/R = "했고 "
G/S = "했는 "
G/SE = "했는데 "
G/E = "했다 "
G/EAS = "했다면 "
G/A = "했으며 "
G/F = "했을 "
G/FE = "했을 때 "
G/FT = "했을 수 "
G/W = "했지 "
G/WA = "했지만 "
GD/ = "하였"
GD/R = "하였고 "
GD/S = "하였는 "
GD/SE = "하였는데 "
GD/E = "하였다 "
GD/EA = "하였다면 "
GD/A = "하였으며 "
GD/F = "하였을 "
GD/FE = "하였을 때 "
GD/FT = "하였을 수 "
GD/WA = "하였지만 "
```

``` txt
E' = "되게 "
ER;W = "되겠습니다. "
ER;WA = "되겠습니다만 "
E^R;W = "되겠습니까? "
ER = "되고 "
ES = "되는 "
E;FR = "되도록 "
EA = "되며 "
EAS = "되면 "
EAT = "되면서 "
EDF = "되므로 "
ED = "되어 "
ED; = "되어도 "
EDT = "되어서 "
EW = "되지 "
EWA = "되지만 "
E;WQ = "됩니다. "
E;WQA = "됩니다만 "
E^;WQ = "됩니까? "
EFT = "될 수 "
E/ = "됐"
E/R = "됐고 "
E/S = "됐는 "
E/S; = "됐는데 "
E/; = "됐다 "
E/EAS = "됐다면 "
E/A = "됐으며 "
E/W = "됐지 "
E/WA = "됐지만 "
E/F = "됐을 "
E/F; = "됐을 때 "
E/FT = "됐을 수 "
ED/ = "되었"
ED/R = "되었고 "
ED/A = "되었으며 "
ED/AS = "되었으면 "
ED/AT = "되었으면서 "
ED/F = "되었으므로 "
ED/W = "되었지 "
ED/WA = "되었지만 "
ED/T;W = "되었습니다. "
ED/T;WA = "되었습니다만 "
ED/^T;W = "되었습니까? "
ED/FT = "되었을 수 "
```

``` txt
JL = "않"
JL' = "않게 "
JLREW = "않겠습니다. "
JLREWA = "않겠습니다만 "
JL^REW = "않겠습니까? "
JLR = "않고 "
JLS = "않는 "
JLSE = "않는데 "
JLE = "않다 "
JLEAS = "않다면 "
JLEFR = "않도록 "
JLA = "않으며 "
JLAS = "않으면 "
JLAT = "않으면서 "
JLDF = "않으므로 "
JLD = "않아 "
JLDE = "않아도 "
JLDT = "않아서 "
JLDS = "않은 "
JLW = "않지 "
JLWA = "않지만 "
JLTEW = "않습니다. "
JLTEWA = "않습니다만 "
JL^TEW = "않습니까? "
JLF = "않을 "
JLF' = "않을까 "
JLFE = "않을 때 "
JLFT = "않을 수 "
JLT = "않아서 "
JL/ = "않았"
JL/R = "않았고 "
JL/S = "않았는 "
JL/SE = "않았는데 "
JL/E = "않았다 "
JL/EAS = "않았다면 "
JL/A = "않았으며 "
JL/F = "않았을 "
JL/FE = "않았을 때 "
JL/FT = "않았을 수 "
JL/W = "않았지 "
JL/WA = "않았지만 "
```

``` txt
UO = "많"
UO' = "많게 "
UOR = "많고 "
UOE = "많다"
UOER = "많다고 "
UOES = "많다는 "
UOEA = "많다며 "
UOEAS = "많다면 "
UOTEW = "많습니다. "
UOTEWA = "많습니다만 "
UO^TEW = "많습니까? "
UOD = "많아 "
UODE = "많아도 "
UODT = "많아서 "
UO/ = "많았"
UO/E = "많았다"
UO/TEW = "많았습니다. "
UO/TEWA = "많았습니다만 "
UO/^TEW = "많았습니까? "
UOM = "많으"
UOA = "많으며 "
UOAS = "많으면 "
UODF = "많으므로 "
UODFT = "많으므로써 "
UODS = "많은 "
UOF = "많을 "
UOFE = "많을 때 "
UOFT = "많을 수 "
UOF' = "많을까 "
UOFW = "많을지 "
UOL = "많이 "
UOW = "많지 "
UOWA = "많지만 "
```

``` txt
IOP = "겠"
IOPR = "겠고 "
IOPS = "겠는 "
IOPSW = "겠는지 "
IOPE = "겠다"
IOPER = "겠다고 "
IOPES = "겠다는 "
IOPEA = "겠다며 "
IOPEAS = "겠다면 "
IOPD = "겠어"
IOPM = "겠으"
IOPMS = "겠으나 "
IOPMA = "겠으며 "
IOPMAS = "겠으면 "
IOPMDF = "겠으므로 "
IOPF = "겠을 "
IOPW = "겠지 "
IOPWA = "겠지만 "
```

``` txt
KL = "있"
KL' = "있게 "
KLR = "있고 "
KLS = "있는 "
KLSE' = "있는데 "
KLSW = "있는지 "
KLE = "있다 "
KLER = "있다고 "
KLSE = "있다는 "
KLEAS = "있다면 "
KLEFR = "있도록 "
KLA = "있으며 "
KLAS = "있으면 "
KLAT = "있으면서 "
KLDF = "있으므로 "
KLD = "있어 "
KLDE = "있어도 "
KLDT = "있어서 "
KLW = "있지 "
KLWA = "있지만 "
KLTEW = "있습니다. "
KLTEWA = "있습니다만 "
KL^TEW = "있습니까? "
KLF = "있을 "
KLFE = "있을 때 "
KLFT = "있을 수 "
KLT = "있어서 "
KL/ = "있었"
KL/R = "있었고 "
KL/S = "있었는 "
KL/SE' = "있었는데 "
KL/E = "있었다 "
KL/ES = "있었다는 "
KL/EAS = "있었다면 "
KL/A = "있었으며 "
KL/F = "있었을 "
KL/FE = "있었을 때 "
KL/FT = "있었을 수 "
KL/W = "있었지 "
KL/WA = "있었지만 "
KL/TEW = "있었습니다. "
KL/TEWA = "있었습니다만 "
KL/^TEW = "있었습니까? "
```

``` txt
JK = "없"
JK' = "없게 "
JKR = "없고 "
JKS = "없는 "
JKSE' = "없는데 "
JKE = "없다 "
JKES = "없다는 "
JKEAS = "없다면 "
JKEFR = "없도록 "
JKA = "없으며 "
JKAS = "없으면 "
JKAT = "없으면서 "
JKDF = "없으므로 "
JKW = "없지 "
JKWA = "없지만 "
JKTEW = "없습니다. "
JKTEWA = "없습니다만 "
JK^TEW = "없습니까? "
JKD = "없어 "
JKDE = "없어도 "
JKDT = "없어서 "
JKZ = "없애"
JKL = "없이 "
JKF = "없을 "
JKFE = "없을 때 "
JKFT = "없을 수 "
JK/ = "없었"
JK/R = "없었고 "
JK/S = "없었는 "
JK/SE' = "없었는데 "
JK/E = "없었다 "
JK/ES = "없었다는 "
JK/EAS = "없었다면 "
JK/D = "없었어 "
JK/DE = "없었어도 "
JK/DT = "없었어서 "
JK/A = "없었으며 "
JK/F = "없었을 "
JK/FE = "없었을 때 "
JK/FT = "없었을 수 "
JK/W = "없었지 "
JK/WA = "없었지만 "
JK/TEW = "없었습니다. "
JK/TEWA = "없었습니다만 "
JK/^TEW = "없었습니까? "
```

``` txt
HJI = "것 같"
HJI' = "것 같게 "
HJIR = "것 같고 "
HJIE = "것 같다"
HJIER = "것 같다고 "
HJIES = "것 같다는 "
HJIEA = "것 같다며 "
HJIEAS = "것 같다면 "
HJITEW = "것 같습니다. "
HJITEWA = "것 같습니다만 "
HJI^TEW = "것 같습니까? "
HJID = "것 같아"
HJIDE = "것 같아도 "
HJIDT = "것 같아서 "
HJIA = "것 같으며 "
HJIAS = "것 같으면 "
HJIAT = "것 같으면서 "
HJIDF = "것 같으므로 "
HJIDF/ = "것 같으므로써 "
HJIS = "것 같은 "
HJIF = "것 같을 "
HJIFE = "것 같을 때 "
HJIFT = "것 같을 수 "
HJIFW = "것 같을지 "
HJIL = "것 같이 "
HJIW = "것 같지 "
```

``` txt
NM = "아니"
NM' = "아니게 "
NMR = "아니고 "
NME = "아니다"
NMFZ = "아니라 "
NMFR = "아니라고 "
NMFS = "아니라는 "
NMFA = "아니라며 "
NMA = "아니며 "
NMAS = "아니면 "
NMAT = "아니면서 "
NMDF = "아니므로 "
NMD = "아니어"
NMDE = "아니어도 "
NMDT = "아니어서 "
NMW = "아니지 "
NMGR = "아니하고 "
NMS = "아닌 "
NMSE = "아닌데 "
NMSW = "아닌지 "
NMF = "아닐 "
NMFE = "아닐 때 "
NMFT = "아닐 수 "
NMF' = "아닐까 "
NMFW = "아닐지 "
NMEWQ = "아닙니다. "
NMEWQA = "아닙니다만 "
NM^EWQ = "아닙니까? "
```

``` txt
BNM = "싶"
BNM' = "싶게 "
BNMR = "싶고 "
BNME = "싶다"
BNM^TEW = "싶습니까? "
BNMTEW = "싶습니다. "
BNMTEWA = "싶습니다만 "
BNMD = "싶어 "
BNMDE = "싶어도 "
BNMDT = "싶어서 "
BNM/ = "싶었"
BNM/E = "싶었다"
BNM/^TEW = "싶었습니까? "
BNM/TEW = "싶었습니다. "
BNM/TEWA = "싶었습니다만 "
BNM/F = "싶었을 "
BNM/W = "싶었지 "
BNMZ = "싶으"
BNMA = "싶으며"
BNMAS = "싶으면"
BNMDS = "싶은 "
BNMF = "싶을 "
BNMFE = "싶을 때 "
BNMFT = "싶을 수 "
BNMF' = "싶을까 "
BNMFW = "싶을지 "
BNMW = "싶지 "
BNMWA = "싶지만 "
```

``` txt
MO = "그래"
MOE = "그래도 "
MOT = "그래서 "
MOI = "그래야 "
MO/ = "그랬"
MO/E = "그랬다"
MO/EA = "그랬다며 "
MO/EAS = "그랬다면 "
MO/TEW = "그랬습니다. "
MO/TEWA = "그랬습니다만 "
MO/^TEW = "그랬습니까? "
MO/F = "그랬을 "
MO/W = "그랬지 "

MJ = "그러"
MJSZ = "그러나 "
MJAS = "그러면 "
MJAT = "그러면서 "
MJDF = "그러므로 "
MJDFT = "그럼으로써 "
MJGS = "그러한 "
MJGF = "그러할 "
MJS = "그런 "
MJSE = "그런데 "
MJSW = "그런지 "
MJF = "그럴 "
MJFE = "그럴 때 "
MJFT = "그럴 수 "
MJF' = "그럴까 "
MJFW = "그럴지 "
MJA = "그럼"
MJDE = "그럼에도 "

MJG = "그렇"
MJ' = "그렇게 "
MJR = "그렇고 "
MJE = "그렇다"
MJER = "그렇다고 "
MJEA = "그렇다며 "
MJEAS = "그렇다면 "
MJ^TEW = "그렇습니까? "
MJTEW = "그렇습니다. "
MJTEA = "그렇습니다만 "
MJW = "그렇지 "
MJWA = "그렇지만 "
RF; = "그리고 "
```

``` txt
JIO = "이래"
JIOE = "이래도 "
JIOF = "이래라 "
JIOT = "이래서 "
JIO/ = "이랬"
JIO/E = "이랬다"
JIO/F = "이랬을 "
JIO/W = "이랬지 "
JI = "이러"
JIAS = "이러면 "
JIAT = "이러면서 "
JIDF = "이러므로 "
JIGS = "이러한 "
JIGF = "이러할 "
JIS = "이런 "
JISE = "이런데 "
JIF = "이럴 "
JIFE = "이럴 때 "
JIFT = "이럴 수 "
JIF' = "이럴까 "
JIFW = "이럴지 "
JIA = "이럼 "
JIG = "이렇"
JI' = "이렇게 "
JIR = "이렇고 "
JIE = "이렇다"
JIER' = "이렇다고 "
JIES' = "이렇다는 "
JIEA' = "이렇다며 "
JIEAS' = "이렇다면 "
JI^TEW = "이렇습니까? "
JITEW = "이렇습니다. "
JIW = "이렇지 "
```

``` txt
UKL = "어떠"
UKLGS = "어떠한 "
UKLGF = "어떠할 "
UKLS = "어떤 "
UKLF = "어떨"
UKLFW = "어떨지 "
UKLG = "어떻"
UKL' = "어떻게 "
UKLR = "어떻고 "
```

``` txt
UI = "나가"
UI' = "나가게 "
UI^REW = "나가겠습니까? "
UIREW = "나가겠습니다. "
UIREWA = "나가겠습니다만 "
UIR = "나가고 "
UIRW = "나가고자 "
UIS = "나가는 "
UISE = "나가는데 "
UIE = "나가다"
UIA = "나가며 "
UIAS = "나가면 "
UIAT = "나가면서 "
UIT = "나가서 "
UID = "나가야 "
UIW = "나가지 "
UIDS = "나간 "
UISE' = "나간다"
UIF = "나갈 "
UIFE = "나갈 때 "
UIFT = "나갈 수 "
UIF' = "나갈까 "
UIFW = "나갈지 "
UI/ = "나갔"
UI/E' = "나갔다"
UI/F = "나갔을 "
```

``` txt
YI = "나아가"
YI' = "나아가게 "
YIR = "나아가고 "
YIDS = "나아가는 "
YIDSE = "나아가는데 "
YIT = "나아가서 "
YIS = "나아간 "
YISE = "나아간다"
YIF = "나아갈"
YIFE = "나아갈 때 "
YIFT = "나아갈 수 "
YIF' = "나아갈까 "
YIFW = "나아갈지 "
YIQWE = "나아갑니다. "
YITQWE = "나아갑시다. "
```

``` txt
HIO = "바라"
HIODS = "바라는 "
HIOE = "바라도 "
HIOT = "바라서 "
HIOS = "바란 "
HIOSE = "바란다"
HIOF = "바랄 "
HIOA = "바람"
HIOWR = "바람직"
HIO^QWE = "바랍니까? "
HIOQWE = "바랍니다. "
HIOQWEA = "바랍니다만 "
```

``` txt
UP' = "밝게 "
UPR = "밝고 "
UPE = "밝다"
UPER = "밝다고 "
UPES = "밝다는 "
UPEA = "밝다며 "
UPEAS = "밝다면 "
UPD = "밝아"
UPDE = "밝아도 "
UPDT = "밝아서 "
UPDS = "밝은 "
UPF = "밝을 "
UPFE = "밝을 때 "
UPFT = "밝을 수 "
UPFW = "밝을지 "
UPGD = "밝혀 "
UPGD/ = "밝혔 "
UPGTEW = "밝혔습니다. "
UPG = "밝히 "
UPGS = "밝힌 "
UPGF = "밝힐 "
```

#### 것 시리즈

``` txt
HJ = "것"
HJE = "것도 "
HJOP = "것에 "
HJOPS = "것에는 "
HJOPE = "것에도 "
HJOPT = "것에서 "
HJDF = "것으로 "
HJDFT = "것으로써 "
HJDS = "것은 "
HJF = "것을 "
HJCF = "것처럼 "
HJQE = "것보다 "

HJL = "것이 "
HJLR = "것이고 "
HJLE = "것이다"
HJLFR = "것이라고 "
HJLFS = "것이라는 "
HJLFA = "것이라며 "
HJLA = "것이며 "
HJLAS = "것이면 "
HJLDF = "것이므로 "
HJLDFT = "것이므로써 "
HJLDAF = "것이야말로 "
HJLW = "것이지 "
HJLS = "것인"
HJLSE = "것인데 "
HJLSW = "것인지 "
HJLF = "것일 "
HJLFE = "것일 때 "
HJLFT = "것일 수 "
HJLF' = "것일까 "
HJLFW = "것일지 "
HJLEWQ = "것입니다. "
HJLEWQA = "것입니다만 "
HJL^EWQ = "것입니까? "
```

#### 때문 시리즈

``` txt
UIO = "때문"
UIOP = "때문에 "
UIL = "때문이 "
UILR = "때문이고 "
UILE = "때문이다"
UILFR = "때문이라고 "
UILFS = "때문이라는 "
UILFA = "때문이라며 "
UILA = "때문이며 "
UILAS = "때문이면 "
UILAT = "때문이면서 "
UILW = "때문이지 "
UILS = "때문인 "
UILSE = "때문인데 "
UILSW = "때문인지 "
UILF = "때문일 "
UILFE = "때문일 때 "
UILFT = "때문일 수 "
UILF' = "때문일까 "
UILFW = "때문일지 "
UILEWQ = "때문입니다. "
UILEWQA = "때문입니다만 "
UIL^EWQ = "때문입니까? "
```

### 일반 단어

#### 겹받침

``` txt
QFRK = "밝"
SFQJ = "넓"
TFAK = "삶"
WFAJ = "젊"
QF; = "밟"
DFGL = "잃"
RSGM = "끊"
RSGMA = "끊임"
RQTK = "값"
```

#### 한국어 단어

``` txt
RAT = "감사"
RFUHI = "결과"
RW = "경제"
RDYB = "교육"
RTD = "구성"
R; = "국가"
RAC = "국무총리"
RA = "국민"
RG; = "국회"
RSMI = "그냥 "
RES = "그동안 "
RQ = "기업"
SDFO = "내일 "
REFK = "까닭"
SFHU = "노력"
ETKL = "다시 "
0RQ = "대기업"
EXF = "대통령"
EGOK = "대한 "
EGAR = "대한민국"
EHI = "도약 "
EDS = "동안 "
EJB = "더욱 "
ETKLJ = "다시 한 번 "
ETKL; = "또다시 "
EFQ = "독립"
A/ = "말씀"
AEHN = "모두 "
AESH = "모든 "
ASWN = "문제"
AFSH = "물론 "
AR; = "미국"
AF; = "미래"
ASW = "민주"
ASWML = "민주주의"
QF = "바로 "
QET = "반드시 "
Q; = "방법"
QS; = "부분"
TFA = "사람"
TG; = "사회"
TGDK = "상황"
TR = "생각"
TW = "성장"
7RQ = "소상공인"
F/ = "스스로 "
TWLK = "시장"
DFKLW = "여러가지 "
DFQN = "여러분"
DSF = "오늘 "
DSFMK = "오늘날 "
DFES = "오랫동안 "
DF; = "우리 "
DFSK = "우리나라"
DSE; = "운동"
DSLNJ = "의원"
DFQ = "일본"
8RQ = "자영업자"
WD = "자유"
WDF = "자율"
WQ = "정부"
WDC = "정책"
WC = "정치"
WRHU = "존경"
WDNML = "주의"
W; = "주장"
WR; = "중국"
9RQ = "중소기업"
WRA = "지금 "
CDA = "책임"
CA = "처음 "
XZ = "특히 "
VG = "평화"
1K = "하나"
GSR = "한국"
GQE = "한반도"
GA' = "함께 "
GQR = "회복 "
```

#### 영단어

``` txt
=A = "APEC"
=G = "G"
=Z = "K"
=IT = "IT"
=IMF = "IMF"
=OECD = "OECD"
```

### 기타

``` txt
1 = "1"
2 = "2"
3 = "3"
4 = "4"
5 = "5"
6 = "6"
7 = "7"
8 = "8"
9 = "9"
0 = "0"
^1 = "!"
^2 = "@"
^3 = "#"
^4 = "$"
^5 = "%"
^6 = "^"
^7 = "&"
^8 = "*"
^9 = "("
^0 = ")"

O1 = "첫째"
O2 = "둘째"
O3 = "셋째"
O4 = "넷째"

0- = "00"
0= = "000"

- = "-"
= = "="
[ = "["
] = "]"
,= ""
. = ". "
,_ = ""
._ = "."
^- = "_"
^= = "+"
^[ = "{"
^] = "}"
^' = "\""
^,= "<"
^. = ">"
^/ = "?"

ASDF": { "key = "enter" },
QWER": { "key = "tab" },
ZXCV": { "key = "backspace" },
ASDFG": { "key = "escape" },
```
