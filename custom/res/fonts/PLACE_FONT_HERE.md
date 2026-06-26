# ქართული ფონტი

ჩასვი `NotoSansGeorgian.ttf` ამ დირექტორიაში.

წყარო (OFL ლიცენზია, კომერციულად თავისუფალი):
- Noto Sans Georgian — https://fonts.google.com/noto/specimen/Noto+Sans+Georgian
- ალტერნატივა: BPG фонтები (bpg-fonts), ან Fira GO (ქართულის მხარდაჭერით)

ფაილის სახელი ზუსტად `NotoSansGeorgian.ttf` უნდა იყოს — ემთხვევა:
- `custom/custom.qrc` (prefix `/custom/fonts`)
- `custom/src/CustomPlugin.cc` (addApplicationFont `:/custom/fonts/NotoSansGeorgian.ttf`)

variable font (wght/wdth ღერძით) პირდაპირ მუშაობს — `addApplicationFont` არეგისტრირებს
ერთ family-ს ყველა weight-ით. ცალკე static weight-ები სავალდებულო არ არის.
