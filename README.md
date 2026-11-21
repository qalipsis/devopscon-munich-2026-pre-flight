# DevOpsCon Munich 2026 — pre-flight

Prepare your computer for the workshop **"From Green Build to Broken Peak"**, at home, before the day.

The workshop runs a complete system on your computer: services, Kafka, a database, monitoring, and the
load-testing tool. All of it comes as Docker images, about 8 GB. The network of a conference
room might be slow and is shared by everybody. So please download everything at home, with this repository.

It takes 10 to 30 minutes, depending on your network. You only need Docker.

**Questions, before or after the workshop:** write to <eric.jesse@qalipsis.com>.

## What you need

- **Docker**, running. Any version that has `docker compose`: Docker Desktop, OrbStack, Rancher Desktop,
  Colima or Docker Engine. On macOS, Windows or Linux, on Intel/AMD or ARM processors.
- **Docker must be allowed to use at least 5 GB of memory**, and have 15 GB of free disk space.
  In Docker Desktop: *Settings → Resources*.
- **Up to 1 GB of free disk space outside Docker**, next to this folder:

  | What | Where | Size |
  |---|---|---|
  | The workshop repository, its builds and the reports of your runs | the folder `devopscon-munich-2026` (step 5) | up to 500 MB |
  | Gradle and Java 21, only when Java is installed, for Gradle on your own computer | the folder `.gradle` of your home folder | about 400 MB |
  | This repository | here | a few MB |

  The Gradle files of the workshop (Gradle, Java 21, the QALIPSIS libraries) go into Docker, in the volume
  `workshop-gradle-cache`: the workshop runs Gradle in a container, so no Java needs to be installed. The
  data the sandbox generates during the workshop (Kafka, PostgreSQL, InfluxDB, Jaeger) also stays in Docker:
  both are part of the 15 GB above.
- **A terminal that runs Bash:**
  - macOS and Linux: the normal terminal.
  - Windows: **Git Bash** (installed with [Git for Windows](https://git-scm.com/download/win)) or a
    **WSL2** terminal.
- **On Windows, PowerShell** as well: Windows PowerShell 5.1, which comes with Windows, or PowerShell 7.
- **Git**, to download this repository.

Java is not needed: Gradle and the scenarios run in a container. If you have a Java, of any version, step 4
also prepares Gradle and Java 21 on your computer, so Gradle can run there too (for example in your IDE);
a Java 22 or newer is fine, Gradle runs on Java 21 anyway.

## How to run it

```shell
git clone https://github.com/qalipsis/devopscon-munich-2026-pre-flight.git
cd devopscon-munich-2026-pre-flight
./preflight.sh
```

The script has five steps. Before each step, it explains **why** the step is needed, **what** it does,
and **what it means for you**. Then you decide:

- press **Enter** to run the step,
- type **s** to skip it,
- type **q** to stop. You can start the script again later; finished steps are fast the second time.

At the end, a summary shows the result of each step. The script writes everything it shows into the
file `preflight.log`. If something goes wrong, send this file with your question.

## The five steps

| Step | Why | What it does | What it means for you |
|---|---|---|---|
| 1. Check your computer | To find problems at home, where you have time to fix them. | Checks Docker, Docker Compose, the memory and disk space of Docker, the free disk space outside Docker, the network ports of the workshop, the connection to the download servers and, on Windows, PowerShell. | Nothing is installed or changed. One very small image (busybox, about 2 MB) is downloaded to measure the disk space. |
| 2. Terms of the workshop images | Three images are not open source. They are lent to you for the workshop only. | Shows the main points of the [terms](#terms-of-the-workshop-images) and asks if you accept them. | If you accept, you may use these images only for the workshop and you may not pass them on. If not, they are not downloaded. |
| 3. Download the images | The images are large and the room network is slow. | Runs `docker pull` for each image of [`images.lock`](images.lock). Among them is *act*, which runs a GitHub Actions workflow on your computer in the last exercise, so you do not have to install it. | Docker uses about 8 GB of disk space more. |
| 4. Prepare Gradle | The workshop compiles test scenarios with Gradle. The first build downloads a lot. | Builds a small project in [`warmup/`](warmup) with exactly the same tools and libraries as the workshop, in a container. If you have a Java, also starts the tiny project [`jdk/`](jdk), which downloads Gradle and Java 21 to your computer. | Up to 1 GB in the Docker volume `workshop-gradle-cache`; with a Java, about 400 MB more in the folder `.gradle` of your home folder. |
| 5. Get the workshop repository | On the day, everything starts from it. | Downloads it next to this folder, on its start branch. If it is not published yet, it says so. | A folder `devopscon-munich-2026` next to this one, a few MB. |

Each step is also a script of its own, which you can run alone:

```shell
scripts/check.sh                   # step 1
scripts/pull.sh --accept-terms     # step 3; --accept-terms means you accept the terms of step 2
scripts/warmup.sh                  # step 4
scripts/clone.sh                   # step 5, also on the day if the repository was not published yet
```

On the day, start from the workshop repository:

```shell
cd ../devopscon-munich-2026
./up.sh
```

Then open the wizard, <http://localhost:1313>: it leads you through the whole workshop.

Without questions: `./preflight.sh --yes --accept-terms`. The terms are never accepted by `--yes` alone.

## What these scripts do not do

- They send nothing about you or your computer anywhere. They only download.
- They do not install anything outside Docker, except the Gradle files of step 4 in your `.gradle`
  folder. They need no administrator rights.
- They do not show the exercises: the workshop repository of step 5 is only the start point, and each
  unit brings its part on the day.

## After the workshop

To free the disk space, delete what the workshop used:

```shell
docker image rm $(awk '!/^#/ { print $2 }' images.lock) busybox:1.37
docker volume rm workshop-gradle-cache
```

And delete the folder `devopscon-munich-2026` next to this one.

The Gradle files in the `.gradle` folder of your home folder are shared with your other Gradle projects.
Delete them only if you do not use Gradle otherwise.

## Terms of the workshop images

The images of the system under test are **proprietary software of AERIS IT Solutions GmbH**. They are
not open source, and the Apache License of this repository does not apply to them:

- `ghcr.io/qalipsis/workshop-platform-ingest`
- `ghcr.io/qalipsis/workshop-platform-persister`
- `ghcr.io/qalipsis/workshop-platform-chaos-board`

AERIS IT Solutions GmbH makes them available as a courtesy, free of charge, on the following terms:

1. **Scope.** You may download these images and run them on computers you control, for the sole purpose
   of taking part in this workshop — preparing for it, attending it and working through its exercises.
   The permission is non-exclusive, non-transferable and cannot be sublicensed.
2. **No redistribution.** You may not pass these images on in any form: no pushing to other registries,
   no mirroring, no sharing of exported image files (`docker save`), no inclusion in other images or
   distributions, and no hosting of them as a service for others.
3. **No other use.** Any use outside this workshop, in particular in production or for commercial
   purposes, requires a separate written agreement with AERIS IT Solutions GmbH.
4. **No modification.** You may not modify, decompile or reverse-engineer the AERIS software in these
   images, except as far as mandatory law permits it (in particular §§ 40d and 40e of the Austrian
   Copyright Act, UrhG).
5. **Withdrawal.** AERIS IT Solutions GmbH may withdraw the images and revoke this permission at any time.
   Once you no longer use them for the workshop, delete them: see [After the workshop](#after-the-workshop).
6. **Liability.** The images are provided free of charge and as they are, without any warranty.
   AERIS IT Solutions GmbH is liable only for intent and gross negligence. This does not limit liability
   for personal injury, under the Austrian Product Liability Act (PHG), or wherever mandatory law — in
   particular the Austrian Consumer Protection Act (KSchG) — does not allow it to be limited.
7. **Applicable law.** Austrian law applies, excluding its conflict-of-law rules and the UN Convention on
   Contracts for the International Sale of Goods. If you use the images as a consumer, the mandatory
   consumer protection of the country where you live still applies.
8. **Open-source components.** These images also contain open-source software, listed below. Each
   component remains under its own licence, and nothing in these terms restricts the rights that licence
   grants you. For the components under the GPL or the LGPL, AERIS IT Solutions GmbH provides the complete
   corresponding source code on request, for at least three years after the workshop, for no more than
   the cost of providing it: write to the address given in the legal disclosure, <https://qalipsis.io/legal-disclosure/>.

#### Open-source components in these images

| Image | Components | Licences |
|---|---|---|
| `workshop-platform-ingest`, `workshop-platform-persister` | Native executables built with GraalVM Community Edition | GPL-2.0 with Classpath Exception (parts of the JDK and of the GraalVM runtime) |
| | Micronaut Framework, Apache Kafka client, Micrometer, OpenTelemetry, Jackson, Netty, Kotlin and kotlinx.coroutines, SnakeYAML, Flyway (persister), HikariCP (persister) | Apache-2.0 |
| | Logback | EPL-1.0 or LGPL-2.1 |
| | PostgreSQL JDBC driver (persister) | BSD-2-Clause |
| | Base image `gcr.io/distroless/cc-debian12`: Debian 12 packages, among them the GNU C Library, libgcc and libstdc++, OpenSSL | LGPL-2.1+ (glibc), GPL-3.0 with GCC Runtime Library Exception (libgcc, libstdc++), Apache-2.0 (OpenSSL), and the licences of the other Debian packages |
| `workshop-platform-chaos-board` | Vue, Pinia | MIT |
| | IBM Plex fonts (via Fontsource) | SIL Open Font License 1.1 |
| | nginx | BSD-2-Clause |
| | Base image `nginx:alpine`: Alpine Linux packages, among them musl, BusyBox, OpenSSL, PCRE2, zlib | MIT (musl), GPL-2.0 (BusyBox), Apache-2.0 (OpenSSL), BSD-3-Clause (PCRE2), Zlib, and the licences of the other Alpine packages |

## Licences

### This repository

The content of this repository is licensed under the [Apache License 2.0](LICENSE).
Copyright 2026 AERIS IT Solutions GmbH.

### Images built by AERIS from open source only

These carry no AERIS proprietary software, so the terms above do not apply. Use and redistribute them
under the licences of their components.

| Image | Content | Licences | Source |
|---|---|---|---|
| `ghcr.io/qalipsis/workshop-platform-qalipsis` | QALIPSIS runtime and web interface | AGPL-3.0 (or a commercial licence from AERIS IT Solutions GmbH) | <https://github.com/qalipsis/qalipsis-oss> |
| | QALIPSIS API modules and plugins | Apache-2.0 | <https://github.com/qalipsis/qalipsis-oss>, <https://github.com/qalipsis/qalipsis-plugins> |
| | The scenarios of the workshop | Apache-2.0 | the workshop repository |
| | Base image `ghcr.io/qalipsis/base`: Eclipse Temurin 21 on Alpine Linux | GPL-2.0 with Classpath Exception (OpenJDK), and the licences of the Alpine packages | <https://github.com/adoptium/temurin-build> |
| `ghcr.io/qalipsis/workshop-platform-act` | act | MIT (the licence text is in the image, `/usr/share/licenses/act/LICENSE`) | <https://github.com/nektos/act> |
| | Docker CLI, base image `docker:28-cli` on Alpine Linux | Apache-2.0, and the licences of the Alpine packages | <https://github.com/docker/cli> |

### Third-party images

Pulled directly from their publishers; AERIS IT Solutions GmbH does not redistribute them. Each one also
contains operating-system packages under their own licences. The licence files shipped in the image
itself are authoritative.

| Image | Software | Licence | Source |
|---|---|---|---|
| `apache/kafka-native:4.1.2` | Apache Kafka, native build | Apache-2.0 | <https://github.com/apache/kafka> |
| `apache/kafka:4.1.2` | Apache Kafka (creates the topics) | Apache-2.0 | <https://github.com/apache/kafka> |
| `postgres:18` | PostgreSQL | PostgreSQL License | <https://www.postgresql.org/about/licence/> |
| `influxdb:2.7` | InfluxDB OSS 2.7 | MIT | <https://github.com/influxdata/influxdb/tree/2.7> |
| `telegraf:1.39` | Telegraf | MIT | <https://github.com/influxdata/telegraf> |
| `danielqsj/kafka-exporter:v1.11.0` | Kafka Exporter | Apache-2.0 | <https://github.com/danielqsj/kafka_exporter> |
| `jaegertracing/jaeger:2.23.0` | Jaeger | Apache-2.0 | <https://github.com/jaegertracing/jaeger> |
| `eclipse-temurin:21-jdk` | Eclipse Temurin (OpenJDK), runs Gradle in `./gate.sh` | GPL-2.0 with Classpath Exception | <https://adoptium.net/> |
| `ghcr.io/gohugoio/hugo` | Hugo, serves the step-by-step pages of the workshop | Apache-2.0 | <https://github.com/gohugoio/hugo> |
| `catthehacker/ubuntu:act-latest` | Ubuntu-based runner of the local pipeline | MIT (image definition), Ubuntu packages under their own licences | <https://github.com/catthehacker/docker_images> |
| `busybox:1.37` | BusyBox, measures the free disk space in step 1 | GPL-2.0 | <https://busybox.net> |
