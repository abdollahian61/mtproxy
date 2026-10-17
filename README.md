# MTProxy Installer

نصب سریع MTProxy رسمی تلگرام روی Ubuntu/Debian با systemd.

## نصب

```bash
git clone https://github.com/abdollahian61/mtproxy.git
cd mtproxy
chmod +x install.sh
sudo FQDN=prx.eidev.ir PORT=8082 ./install.sh
```

اگر FQDN نداری:

```bash
sudo PORT=8082 ./install.sh
```

اسکریپت به‌صورت خودکار:

- dependencyها را نصب می‌کند
- MTProxy رسمی Telegram را build می‌کند
- `proxy-secret` و `proxy-multi.conf` را دانلود می‌کند
- Secret اختصاصی می‌سازد
- systemd service ایجاد می‌کند
- سرویس را enable/start می‌کند
- در صورت فعال بودن UFW، پورت را باز می‌کند
- لینک `tg://proxy` را نمایش می‌دهد

## بررسی وضعیت

```bash
systemctl status mtproxy --no-pager
systemctl is-enabled mtproxy
systemctl is-active mtproxy
ss -lntp | grep ':8082 '
```

## لاگ

```bash
journalctl -u mtproxy -f
```

## نمایش Secret

```bash
cat /etc/mtproxy.secret
```

## ساخت مجدد لینک

```bash
echo "tg://proxy?server=prx.eidev.ir&port=8082&secret=$(cat /etc/mtproxy.secret)"
```

## تغییر پورت

مثلاً:

```bash
sudo PORT=443 FQDN=prx.eidev.ir ./install.sh
```

پیش‌فرض اسکریپت `8082` و `2` worker است.
