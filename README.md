# Oedge OS

Oedge OS, Origin Edge teknoloji ekosisteminden esinlenen bağımsız ve küçük bir
x86 BIOS önyükleme/komut satırı deneyi. Oedge.xyz'nin resmî ürünü değildir;
şirketle bağlantısı veya şirketin onayı yoktur. Şirketin marka varlıklarını
kopyalamaz.

## Neler çalışıyor?

- 512 baytlık BIOS açılış sektörü, ham 1,44 MiB disket imajından çekirdeği yükler.
- 16 bit gerçek mod çekirdeği VGA metin arayüzünü çizer ve BIOS klavye hizmetiyle
  tuş girişini okur.
- Kabuk `help`, `about`, `status`, `time`, `echo <metin>`, `clear` ve `reboot`
  komutlarını destekler. Komutlar büyük/küçük harfe duyarsızdır.
- `time`, BIOS uyumlu bilgisayar yazılımının gerçek zaman saatini okur.

Arayüz, standart PC metin kipinde okunabilmesi için yalnızca ASCII karakterlerini
kullanır.

## Gereksinimler

- Python 3.9 veya yenisi (yalnızca standart kütüphane).
- NASM 2.15 veya yenisi; `nasm` komutu `PATH` içinde olmalı.
- Sanal makinede çalıştırmak için QEMU (isteğe bağlı, ayrı kurulur).

Windows'ta NASM ve QEMU'yu winget ile kurabilirsiniz:

```powershell
winget install --id NASM.NASM --exact
winget install --id SoftwareFreedomConservancy.QEMU --exact
```

## Derleme

Depo kök dizininde:

```powershell
python tools\build.py
```

Oluşan `build\oedge-os.img`, ham 1,44 MiB disket imajıdır. Önyükleyici sonraki
17 sektörü okur; bu nedenle çekirdek en fazla 8.704 bayt olabilir.

## QEMU'da çalıştırma

```powershell
qemu-system-i386 -drive file=build\oedge-os.img,format=raw,if=floppy
```

Kurulumunuzda QEMU'nun çalıştırılabilir dosyasının adı farklıysa uygun komut
adını kullanın. İmajı gerçek diske yazmayın; tek kullanımlık bir sanal makinede
deneyin. `oedge>` isteminde `help`, `status`, `time` veya `echo merhaba`
komutlarını deneyebilirsiniz.

## Testler

```powershell
python -m unittest discover -s tests -v
```

Testler disket imajı düzenini denetler; geçersiz açılış sektörlerini ve fazla
büyük çekirdekleri reddeder. CPU emülasyonu yapmaz ve fiziksel donanımda
çalıştığını kanıtlamaz.

## Kapsam ve sınırlar

Bu, öğrenme amaçlı küçük bir BIOS/gerçek mod prototipidir; genel amaçlı veya
üretime hazır bir işletim sistemi değildir. Eski BIOS önyüklemesi (veya bunu
taklit eden bir sanal makine) gerekir; yalnızca UEFI ile açılmaz. Dosya sistemi,
kalıcı depolama, bellek yönetimi, korumalı/uzun mod, süreç modeli, ağ, USB
desteği veya BIOS hizmetleri dışında donanım sürücüleri yoktur. Gerçek donanımda
çalıştığına dair bir iddia yoktur.
