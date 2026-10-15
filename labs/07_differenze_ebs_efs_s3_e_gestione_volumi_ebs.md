# Lab 07 - Differenze tra EBS, EFS e S3 e Gestione dei Volumi EBS

## Obiettivo

- Focus operativo: creare, allegare, montare e mettere in backup un volume EBS dedicato, restando entro i limiti di tipo/dimensione del Learner Lab.
- Deliverable atteso: volume EBS creato/allegato/montato, file di test scritto con successo, snapshot in stato `completed`.
- Nomi di risorsa usati in questa soluzione: volume `demo-data-vol`, device richiesto `/dev/sdf` (nome reale da verificare nel sistema operativo), mount point `/mnt/demo-data`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con un'istanza EC2 in esecuzione (es. dai lab precedenti).
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Accesso SSH all'istanza per montare il volume dal sistema operativo.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare tipo, dimensione e Availability Zone del volume pianificato su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve aggiungere spazio dati dedicato a un'istanza applicativa, separato dal volume radice del sistema operativo.
- Devi creare un volume EBS coerente con i limiti della policy del Learner Lab (tipo `gp2`/`gp3`/`sc1`/`standard`, massimo 100 GiB), allegarlo e montarlo.
- Devi produrre uno snapshot del volume come backup e verificarne lo stato prima di concludere il lab.

## Step

1. Confrontare i modelli: **EBS** è un disco a blocchi (i volumi `gp3` di questo lab si allegano a una sola istanza nella stessa AZ); **EFS** è un file system condiviso; **S3** conserva oggetti accessibili via API. Annotare un caso d'uso per ciascuno.
2. Scegliere un'istanza Linux raggiungibile in SSH, indipendente dall'ASG; riavviare `demo-web-01` o crearne una con il Lab 01 se necessario. Annotarne l'Availability Zone in **EC2 → Instances → Details**.
3. Aprire **EC2 → Elastic Block Store → Volumes → Create volume**: tipo `gp3`, 10 GiB, stessa AZ dell'istanza, tag `Name = demo-data-vol`; scegliere **Create volume**.
4. Attendere `available`, selezionare il volume → **Actions → Attach volume**, scegliere l'istanza e richiedere device `/dev/sdf`. Annotare Volume ID e attendere `in-use`.
5. Collegarsi in SSH, identificare il disco dati con `lsblk -f` e confrontare ID/dimensione con il volume appena allegato. Il nome reale può essere `/dev/xvdf` o un device NVMe; non usare il disco di sistema. Formattare solo il nuovo volume vuoto e montarlo come indicato sotto.
6. Scrivere e rileggere `/mnt/demo-data/test.txt`; usare `findmnt /mnt/demo-data` per verificare il mount, oltre allo stato di allegamento nella console.
7. Terminare le scritture ed eseguire `sync`. In **Volumes → demo-data-vol → Actions → Create snapshot**, descrizione `backup volume dati del laboratorio`; in **Snapshots** attendere `completed` e annotare Snapshot ID.
8. Documentare tipo, dimensione, AZ, device reale, file e snapshot. Conservare volume e snapshot se serviranno ai Lab 10, 12 e 14; altrimenti eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento     | Evidenza sintetica                                                    |
| ---: | ------------ | --------------------------------------------------------------------- |
|    1 | Volume EBS   | `demo-data-vol`, `gp3`, 10 GiB, stessa AZ dell'istanza (`us-east-1a`) |
|    2 | Device       | richiesto `/dev/sdf`, visto dal sistema operativo come `/dev/xvdf`    |
|    3 | Mount point  | `/mnt/demo-data`, file system `ext4`                                  |
|    4 | File di test | `test.txt` scritto e letto correttamente in `/mnt/demo-data`          |
|    5 | Snapshot     | creato da `demo-data-vol`, stato `completed`                          |

## Comandi eseguiti e output

Formattazione, montaggio e scrittura del file di test (eseguiti in SSH sull'istanza):

**Ubuntu (bash) / macOS (zsh/bash) / Windows PowerShell (dopo accesso SSH alla EC2 Linux)**

Prima di eseguire il blocco, impostare `LAB_DATA_DEVICE` al device dati reale identificato. Nell'esempio `/dev/xvdf` è solo un segnaposto: sulle istanze Nitro può essere `/dev/nvme1n1`. Se `lsblk -f` o `blkid` mostrano un file system esistente, saltare `mkfs` e montare quello esistente.

```bash
lsblk -f
LAB_DATA_DEVICE=/dev/xvdf
sudo blkid "$LAB_DATA_DEVICE"
# Solo per il volume appena creato, vuoto e verificato:
sudo mkfs -t ext4 "$LAB_DATA_DEVICE"
sudo mkdir -p /mnt/demo-data
sudo mount "$LAB_DATA_DEVICE" /mnt/demo-data
findmnt /mnt/demo-data
echo "demo storage EBS" | sudo tee /mnt/demo-data/test.txt
cat /mnt/demo-data/test.txt
```

Output atteso:

```
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0   8G  0 disk /
xvdf    202:80   0  10G  0 disk

demo storage EBS
demo storage EBS
```

Verifica dello stato del volume e dello snapshot via AWS CLI:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-volumes --filters "Name=tag:Name,Values=demo-data-vol" \
  --query "Volumes[].{State:State,Size:Size,Type:VolumeType,AZ:AvailabilityZone}"

aws ec2 describe-snapshots --owner-ids self \
  --filters "Name=volume-id,Values=<volume-id-demo-data-vol>" \
  --query "Snapshots[].{State:State,Progress:Progress}"
```

**Windows PowerShell**

```powershell
aws ec2 describe-volumes --filters "Name=tag:Name,Values=demo-data-vol" `
  --query "Volumes[].{State:State,Size:Size,Type:VolumeType,AZ:AvailabilityZone}"

aws ec2 describe-snapshots --owner-ids self `
  --filters "Name=volume-id,Values=<volume-id-demo-data-vol>" `
  --query "Snapshots[].{State:State,Progress:Progress}"
```

Output atteso (illustrativo: gli ID reali variano a ogni creazione):

```
[{"State": "in-use", "Size": 10, "Type": "gp3", "AZ": "us-east-1a"}]
[{"State": "completed", "Progress": "100%"}]
```

Il campo `State: in-use` conferma l'allegamento; `findmnt` e la lettura del file confermano il montaggio; `State: completed` con `Progress: 100%` conferma che lo snapshot è pronto come backup.

## Template operativo

```markdown
# Deliverable Lab 07

## Volume EBS
- Nome: demo-data-vol
- Tipo: gp3
- Dimensione: 10 GiB
- Availability Zone: us-east-1a (stessa dell'istanza)
- Device: /dev/sdf (visto come /dev/xvdf)

## Verifica funzionamento
- Mount point: /mnt/demo-data
- File di test scritto e letto: si

## Snapshot
- Stato: completed

## Cleanup
- Volume smontato e staccato: si/no
- Volume eliminato: si/no
- Snapshot eliminato (se non più necessario): si/no
```

## Esempio sintetico

- Decisione corretta: `gp3` a 10 GiB resta ampiamente dentro i limiti del Learner Lab (100 GiB, tipi consentiti), senza bisogno di richiedere dimensioni o tipi superiori.
- Evidenza minima: output di `lsblk` che mostra il nuovo device, contenuto del file di test letto correttamente, stato dello snapshot `completed`.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare tipo, dimensione e AZ del volume pianificato su tabella Markdown.
- Cleanup atteso: volume smontato, staccato ed eliminato; snapshot rimosso se non serve ai lab successivi (se si prosegue, conservare `demo-data-vol` per i Lab 10/14 e lo snapshot per il Lab 12).

## Checkpoint

- [x] Volume EBS di tipo consentito e dimensione entro i 100 GiB del Learner Lab
- [x] Volume creato nella stessa Availability Zone dell'istanza a cui viene allegato
- [x] Snapshot creato e verificato nello stato `completed`
- [x] Cleanup eseguito o esplicitamente giustificato (es. mantenuto per un lab successivo)

## Errori comuni da evitare

- Richiedere un volume in una Availability Zone diversa da quella dell'istanza: l'allegamento fallisce.
- Richiedere un tipo `io1`/`io2` o una dimensione superiore a 100 GiB: la policy del Learner Lab rifiuta la richiesta.
- Assumere che il device compaia con lo stesso nome richiesto (`/dev/sdf`): verificare sempre con `lsblk` il nome reale assegnato dal sistema operativo.
- Considerare lo snapshot "pronto" mentre è ancora in stato `pending`: attendere `completed` prima di documentarlo come backup valido.

## Troubleshooting rapido

- Se l'allegamento del volume fallisce, verifica che volume e istanza siano nella stessa Availability Zone.
- Se la richiesta di creazione del volume viene rifiutata, verifica di non aver richiesto un tipo `io1`/`io2` o una dimensione superiore a 100 GiB, non consentiti dalla policy del Learner Lab.
- Se il device non compare nell'istanza dopo l'attach, verifica con `lsblk` (Linux) il nome effettivo assegnato dal sistema operativo, che può differire dal nome richiesto.
- Se lo snapshot resta a lungo in stato `pending`, attendi qualche minuto: il tempo di completamento dipende dalla dimensione dei dati da copiare.

## Cleanup obbligatorio

Se prosegui con i Lab 10, 12 o 14, conserva le risorse necessarie e annota gli ID nel deliverable. Ferma l'istanza quando non è in uso; volumi e snapshot conservati continuano a occupare storage. Se non servono più, procedi così.

- Esegui `sudo umount /mnt/demo-data`, poi **Volumes → Actions → Detach volume**; attendi `available` prima di eliminarlo.
- Elimina il volume EBS di test, dopo aver verificato che non contenga dati necessari.
- Elimina lo snapshot creato per l'esercitazione, se non più necessario.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
