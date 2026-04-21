[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5V8N3XFTU495G)

# OpenMasterdata-for-Delphi

Aktuell umgesetzte Version ist 9.x.x

## Hinweise zum aktuellen Datenstand

Die mitgelieferte YAML/OpenAPI-Dokumentation ist nicht in allen Punkten auf dem neuesten Stand. Für die aktuelle Implementierung wurden daher zusätzlich die realen Beispiel-Responses als Referenz verwendet.

Wichtige Erkenntnisse aus den Beispiel-Responses:

 - Einige Felder kommen je nach Lieferant sowohl als String als auch als numerischer JSON-Wert vor, z. B. `gtin`, `packagingQuantity`, `durabilityPeriod` oder `standardDeliveryPeriod`.
 - Datumsfelder sind nicht vollständig einheitlich. Neben ISO-Datumswerten kommen auch Formate wie `YYYYMMDD` vor.
 - `additional.expiringProduct` ist nicht zuverlässig nur boolesch interpretierbar. In den Responses kommen Zustände wie `No`, `Yes` und `Yes-Successor` vor.
 - In Attributlisten treten zusätzliche Felder wie `attributeClass`, `attributeValue2`, `attributeValue1Desc` und `attributeValue2Desc` auf.
 - In einzelnen Responses existieren Feldabweichungen bzw. Inkonsistenzen wie `reachData` statt `reachDate`.
 - Bei Attribut-Beschreibungsfeldern gibt es eine Benennungsabweichung: die Doku und generierte DTOs verwenden eher `attributeValue1Descr` / `attributeValue2Descr`, reale Lieferanten-Responses liefern jedoch auch `attributeValue1Desc` / `attributeValue2Desc`.
 - Dokument- und Medienlisten unterscheiden sich je nach Lieferant teilweise in Vollständigkeit und Typisierung, deshalb sollte der Parser tolerant gegen fehlende optionale Felder bleiben.

Die aktuelle Delphi-Implementierung ist auf diese Abweichungen ausgelegt und versucht, die Daten möglichst robust und verlustarm zu laden.

## Implementierungsstand

Aktuell berücksichtigt der Loader insbesondere folgende Fälle:

 - Robustes Einlesen von String- und Zahlenwerten für identische Fachfelder.
 - Robustes Parsen gängiger Datumsformate aus den bekannten Lieferanten-Responses.
 - Unterstützung der neueren Attributfelder in `additional.attribute`.
 - Unterstützung beider Schreibweisen bei Attribut-Beschreibungen: `...Desc` und `...Descr`.
 - Unterstützung des erweiterten Auslaufstatus über `expiringProduct`.
 - Fallback von `reachDate` auf `reachData`.
 - Unterstützung zusätzlicher Dokumenttypen wie `PL`.

Wenn neue Lieferanten angebunden werden, sollten die gelieferten Beispiel-Responses immer gegen die vorhandene Parserlogik geprüft werden, auch wenn sie formal zur 9.x-Dokumentation passen.

Weitere Informationen unter 

 - https://www.itek.de/beratung/open-masterdata
 - https://itek-branchenwissen.atlassian.net/wiki/spaces/DS/pages/535593021/Open+Masterdata

# Lieferanten mit Open Masterdata-Unterstützung

| Lieferant | ja | geplant | nein |
|----------|----------|----------|----------
| GC-Gruppe | x | - | - |
| Pietsch | x | - | - |
| Pürsch | - | - | x |
| Sanitär-Heinze | x | - | - |
| ZVSHK | x | - | - |

## Art der Authentifizierung

 - GC-Gruppe: ClientID, Client-Secret - Registrierung erforderlich
 - Pietsch:
 - Sanitär-Heinze: CliendID (eigene ID) - Registrierung erforderlich
 - ZVSHK: CliendID (eigene ID) - Registrierung erforderlich

# Lizenz / License

License OpenMasterdata-for-Delphi

Copyright (C) 2026 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
