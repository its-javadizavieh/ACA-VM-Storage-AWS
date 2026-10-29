# Esempio integrativo IaC 02 - S3, versioning e drift con Terraform

## Obiettivo

Tradurre in Terraform parte dei **Lab 08 e 09 di VM, Reti e Storage con AWS**: bucket S3 privato, versioning, cifratura SSE-S3 e tag. Durata indicativa **75–90 minuti**; soluzione completa nella cartella [terraform-s3](iac_esempi/terraform-s3/).

Il percorso riprende HCL, provider, variabili, piano, state e drift del corso IaC. Si lavora su un bucket nuovo, distinto dai bucket degli altri lab. Il risultato atteso è saper spiegare ogni cambiamento prima di applicarlo.

## Prerequisiti

- Conoscere bucket/versioni e cifratura dai Lab 08/09; aver visto le basi di Terraform.
- Terraform **>= 1.11 e < 2.0**, AWS CLI e un editor. Per l'installazione usa le [istruzioni ufficiali](https://developer.hashicorp.com/terraform/install).
- Per il percorso AWS: Learner Lab avviato, credenziali temporanee complete e `aws sts get-caller-identity` riuscito.
- Per scaricare il provider al primo `terraform init` serve Internet anche se si usa solo il test simulato.

La configurazione usa il provider `hashicorp/aws` 6.x e ammette solo `us-east-1` e `us-west-2`. Non crea IAM, EC2, NAT Gateway, chiavi KMS personalizzate, Object Lock o pipeline. S3 conserva oggetti e versioni e addebita storage/richieste: usare pochi file piccoli ed eseguire il cleanup.

## Prima di usare le credenziali

Nel Learner Lab apri **AWS Details → AWS CLI → Show**. Inserisci nel profilo locale scelto **tutte e tre** le credenziali temporanee: access key, secret key e session token. Per il profilo `default`, il file è `~/.aws/credentials` (Windows: cartella `.aws` del tuo utente). Conserva gli altri profili già presenti.

Il provider legge la normale catena di credenziali AWS: non inserire chiavi nei `.tf` o nei `.tfvars`. Con un profilo nominato imposta `AWS_PROFILE` nello stesso terminale; con credenziali scadute aggiorna l'intero blocco. Se l'identità restituita è sbagliata, risolvi prima di applicare.

## Step 1 - Aprire il progetto e valorizzare gli input

Apri il terminale nella cartella **`iac_esempi/terraform-s3`**, non nella cartella degli altri progetti Terraform.

**Ubuntu/bash e macOS/zsh:**

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Windows PowerShell:**

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Modifica `terraform.tfvars` in un editor:

```hcl
aws_region = "us-east-1"
student_id = "rossi01"
owner      = "Mario Rossi"
```

`student_id` deve avere 3–12 caratteri minuscoli, numeri o trattini, iniziando con una lettera. Il provider aggiunge un suffisso al prefisso del bucket per limitarne i conflitti di nome. Leggi il nome effettivo dall'Output dopo l'apply.

## Step 2 - Capire le quattro risorse

| File/blocco                                                    | Funzione                                              |
| -------------------------------------------------------------- | ----------------------------------------------------- |
| `versions.tf`                                                  | Versioni di Terraform e provider                      |
| `variables.tf`                                                 | Input e validazioni, incluse le regioni consentite    |
| `aws_s3_bucket.documents`                                      | Bucket e tag di ownership/costo                       |
| `aws_s3_bucket_public_access_block.documents`                  | Tutte e quattro le opzioni Block Public Access attive |
| `aws_s3_bucket_versioning.documents`                           | Versioning `Enabled`                                  |
| `aws_s3_bucket_server_side_encryption_configuration.documents` | Cifratura predefinita SSE-S3/AES256                   |
| `outputs.tf`                                                   | Nome reale, ARN e regione                             |

Un bucket AWS corrisponde qui a **quattro resource Terraform**, perché la sua configurazione è gestita da risorse separate. I riferimenti `aws_s3_bucket.documents.id` introducono dipendenze senza dover elencare manualmente l'ordine.

`force_destroy = false` impedisce di eliminare automaticamente il contenuto quando si distrugge il bucket. Non è una protezione contro la cancellazione di un bucket già vuoto.

## Step 3 - Controlli e percorso senza accesso AWS

Questi comandi sono uguali in **Ubuntu/bash, macOS/zsh e Windows PowerShell**:

```bash
terraform version

terraform init

terraform fmt -check -recursive

terraform validate

terraform test
```

Il test fornito usa `mock_provider "aws"` e solo `command = plan`: controlla blocco pubblico, versioning, cifratura, tag e rifiuto di input non validi **senza credenziali e senza risorse AWS**. Risultato atteso: **3 run superati**. Le due prove con input errati passano proprio perché la configurazione li rifiuta.

Questo verifica la configurazione, non permessi, connessioni, disponibilità del servizio o dati realmente salvati. Se non hai accesso AWS, fermati qui e consegna codice, risultati e risposte teoriche. Un normale `terraform plan` fuori dal test continua a richiedere credenziali valide: non usare credenziali inventate come sostituto del test.

Se `fmt -check` segnala differenze, esegui `terraform fmt -recursive`, poi ripeti il controllo.

## Step 4 - Il piano reale e la creazione

Per proseguire con AWS, verifica l'identità, poi crea un piano salvato:

```bash
aws sts get-caller-identity --region us-east-1

terraform plan -out=creazione.tfplan

terraform show creazione.tfplan
```

Da una cartella/state nuovi, il piano deve indicare **4 to add, 0 to change, 0 to destroy**. Leggi i quattro blocchi e spiega perché nome finale e ARN possono risultare `known after apply`.

Il comando successivo esegue il piano già approvato senza chiedere un altro `yes`: usalo solo dopo averlo controllato. Se le credenziali sono scadute o hai cambiato codice/input, genera un nuovo piano.

```bash
terraform apply creazione.tfplan

terraform output

terraform state list
```

Attese quattro risorse nello state e un bucket nella console. `terraform.tfstate` collega gli indirizzi del codice agli ID AWS: non cancellarlo per risolvere un errore e non pubblicarlo. Il `.gitignore` incluso esclude state, piani e input locali; **`.terraform.lock.hcl` va invece conservato** per fissare le versioni selezionate.

Questo esempio usa lo state locale per il lavoro individuale. In produzione il corso IaC approfondisce backend remoto, locking e collaborazione: il bucket di questo esercizio contiene documenti, non ospita il proprio state.

## Step 5 - Verificare configurazione e versioni

Con il nome da `terraform output -raw bucket_name`, apri **S3 → bucket → Properties/Permissions** e conferma:

- Versioning `Enabled`;
- Default encryption SSE-S3;
- tutte le opzioni Block Public Access abilitate;
- tag `Owner`, `Project`, `Env`, `CostCenter`, `ManagedBy`.

Puoi usare questi comandi **su una riga, uguali nei tre terminali**, sostituendo `NOME_BUCKET_REALE` con l'Output effettivo:

```bash
aws s3api get-bucket-versioning --region us-east-1 --bucket NOME_BUCKET_REALE

aws s3api get-public-access-block --region us-east-1 --bucket NOME_BUCKET_REALE

aws s3api get-bucket-encryption --region us-east-1 --bucket NOME_BUCKET_REALE
```

Attendi la propagazione della prima abilitazione del versioning prima di scrivere oggetti; AWS raccomanda di attendere 15 minuti. Durante l'attesa puoi completare gli Step 6 e 7. [Indicazioni AWS sul versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/manage-versioning-examples.html).

Per la prova dati, crea `report.txt` localmente con un editor, caricalo in console con **Upload**, modifica il testo e ricaricalo nella stessa posizione. Con **Show versions**, individua due Version ID diversi. Verifica la cifratura dell'ultima versione:

```bash
aws s3api list-object-versions --region us-east-1 --bucket NOME_BUCKET_REALE --prefix report.txt

aws s3api head-object --region us-east-1 --bucket NOME_BUCKET_REALE --key report.txt --query ServerSideEncryption
```

Atteso `AES256`. L'upload modifica i dati del bucket, non la configurazione infrastrutturale gestita da Terraform; gli oggetti non sono resource di questo progetto.

## Step 6 - Modifica intenzionale e idempotenza

In `terraform.tfvars`, cambia solo `owner`, poi:

```bash
terraform plan -out=tag.tfplan

terraform show tag.tfplan

terraform apply tag.tfplan

terraform plan
```

Atteso: un aggiornamento in-place dei tag del bucket, con nome/ARN invariati; dopo l'apply, `No changes` se nessuno ha modificato la configurazione. Non assumere che quattro resource nello state implichino quattro modifiche per ogni parametro.

## Step 7 - Drift controllato

1. Nella console S3 cambia **solo** il tag `Owner` del bucket in `test-drift`. Non modificare blocco pubblico o cifratura.
2. Esegui `terraform plan`. Individua il valore effettivo e la correzione proposta verso l'`owner` dichiarato nei tuoi input.
3. Esegui `terraform plan -out=riconciliazione.tfplan`, controlla con `terraform show riconciliazione.tfplan` e applica con `terraform apply riconciliazione.tfplan`.
4. Verifica il tag in console ed esegui di nuovo `terraform plan`: atteso `No changes`.

Il piano legge anche la realtà tramite il provider; lo state da solo non dimostra come sia configurata oggi la risorsa. `terraform plan -refresh-only` serve per osservare gli scostamenti nello state, non propone di riportare AWS alla configurazione dichiarata.

## Step 8 - Capire una sostituzione senza eseguirla

Annota lo `student_id` originale, cambialo temporaneamente in un altro identificativo valido, quindi esegui **solo**:

```bash
terraform plan
```

Il prefisso del nome cambia e il piano propone di sostituire il bucket; anche le configurazioni dipendenti possono essere ricreate. Individua `-/+` o `+/-`, annota la motivazione e **non applicare questo esperimento**. Ripristina lo `student_id` originale e controlla che il piano torni senza modifiche prima del cleanup.

## Cleanup obbligatorio

1. Leggi e annota il nome del bucket prima di distruggere lo state.
2. Se hai caricato file, in **S3 → bucket dell'esercizio → Empty**, elimina **tutte le versioni e tutti i delete marker**, seguendo la conferma della console. Verifica che sia il bucket con il tuo prefisso. La sola cancellazione della versione corrente non basta.
3. Dalla cartella del progetto, con gli input originali ripristinati:

```bash
terraform plan -destroy -out=pulizia.tfplan

terraform show pulizia.tfplan

terraform apply pulizia.tfplan

terraform state list
```

4. Atteso: quattro risorse distrutte, state senza risorse gestite e bucket assente dalla console. Se non avevi eseguito un deploy, non c'è nulla da distruggere.

`BucketNotEmpty` significa che sono rimasti dati/versioni: svuota il bucket dell'esercizio e rilancia il piano di distruzione. Non cancellare lo state e non impostare `force_destroy = true` per saltare la verifica dei dati. Il comando `aws s3 rm --recursive` non elimina da solo tutte le versioni di un bucket versionato.

## Deliverable e soluzione ragionata

Consegna i `.tf`, il file `.terraform.lock.hcl`, un esempio di input senza segreti e una breve tabella:

| Evidenza                    | Risposta attesa                                              |
| --------------------------- | ------------------------------------------------------------ |
| Risorse dopo il primo apply | Quattro indirizzi Terraform, un bucket reale                 |
| Prima modifica del tag      | `~`, aggiornamento in-place                                  |
| Nessuna modifica successiva | `No changes`                                                 |
| Tag alterato in console     | Drift osservato e piano che propone la riconciliazione       |
| Cambio del prefisso         | Sostituzione del bucket, piano letto e non applicato         |
| Due upload                  | Due versioni di `report.txt`, ultima con `AES256`            |
| Cleanup                     | Bucket svuotato, quattro risorse eliminate, verifica console |

Non consegnare credenziali, state, piani binari o screenshot con segreti. Se svolto solo con mock, indicare **test simulato, deploy AWS non eseguito** e non compilare evidenze cloud inventate.

## Errori comuni e approfondimenti

- **ExpiredToken / InvalidClientTokenId:** aggiorna tutte le credenziali temporanee e verifica di nuovo l'identità.
- **Error acquiring the state lock:** controlla se hai già un comando in esecuzione sullo stesso progetto; non forzare lo sblocco senza verificarlo.
- **No valid credential sources:** il test mock può passare comunque; un piano AWS richiede credenziali vere.
- **AccessDenied:** confronta regione e azione negata con le policy del Learner Lab; non tentare di creare o modificare ruoli per risolvere questo esempio.
- **Download provider fallito:** `init` richiede accesso a registry e download; la modalità mock evita le API AWS, non il download iniziale.

Riferimenti: [mock provider e limiti dei test](https://developer.hashicorp.com/terraform/language/tests/mocking), [piani Terraform](https://developer.hashicorp.com/terraform/tutorials/cli/plan), [risorsa S3 e force_destroy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket).
