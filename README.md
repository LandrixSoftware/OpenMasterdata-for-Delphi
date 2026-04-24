[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5V8N3XFTU495G)

# OpenMasterdata-for-Delphi

Aktuell umgesetzte Version ist 9.0.2

Echte Response-Beispiele aus der Praxis sind ausdruecklich willkommen. Wenn Sie konkrete Responses aus produktiven oder realistischen Testszenarien zur Verfuegung stellen koennen, hilft das sehr dabei, Parser, Datenmodell und Darstellung gezielt gegen die tatsaechlich vorkommenden Varianten zu verbessern.

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
 - Die Diskussion zu `prices.rawMaterial` zeigt, dass einzelne Rohstoff-Beispielabbildungen in der bereitgestellten Doku fachlich widerspruechlich oder spaeter als fehlerhaft korrigiert sind. Insbesondere die Kombination aus `weightBasis`, `basisUnit`, `proportionByWeight` und `quotationOfRawMaterial` sollte immer gegen aktuelle Herstellerbeispiele oder abgestimmte Fachinterpretationen geprueft werden.
 - Fuer Rohstoffangaben ist relevant, dass `rawMaterial` mehrfach vorkommen kann. Die Daten sollten daher als Liste und nicht als Einzelobjekt behandelt werden.
 - In der Diskussion wird zusaetzlich ein moegliches Feld `rawMaterial/materialprice` erwaehnt. Dieses Feld ist nicht Teil der aktuell umgesetzten 9.0.2-Struktur und wird in der Bibliothek derzeit nicht geparst.

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
 - Unterstützung von Rohstofflisten unter `prices.rawMaterial`, inklusive `weightBasis`, `basisUnit`, `proportionByWeight`, `proportionUnit`, `quotationOfRawMaterial` und `currentQuotationOfRawMaterial`.
 - Sichtbare HTML-Ausgabe für Alternativartikel, Nachfolgeartikel, Zubehörartikel und Rohstoffangaben.

## Hinweise zu Rohstoffangaben

Die Dokumentation zu den Rohstoffangaben ist nicht durchgehend konsistent. In der mitgelieferten Diskussion zu `rawMaterial` wird ein urspruengliches Beispiel spaeter ausdruecklich als fachlich fehlerhaft bezeichnet.

Fuer die Implementierung bedeutet das:

 - `prices.rawMaterial` wird als Liste geladen, da mehrere Rohstoffzuschlaege pro Artikel vorkommen koennen.
 - Die aktuell umgesetzten Felder sind `material`, `weightBasis`, `basisUnit`, `proportionByWeight`, `proportionUnit`, `quotationOfRawMaterial` und `currentQuotationOfRawMaterial`.
 - Die fachliche Bedeutung von `weightBasis` und `basisUnit` sollte bei neuen Lieferanten nicht allein aus der Doku abgeleitet werden, sondern immer gegen echte Responses oder abgestimmte Fachbeispiele verifiziert werden.
 - Das in der Diskussion genannte Feld `materialprice` ist derzeit nicht Teil des Parsers, weil es in den bisher beruecksichtigten 9.x-Beispielen nicht stabil als Response-Feld belegt ist.

Wenn neue Lieferanten angebunden werden, sollten die gelieferten Beispiel-Responses immer gegen die vorhandene Parserlogik geprüft werden, auch wenn sie formal zur 9.x-Dokumentation passen.

Weitere Informationen unter 

 - https://www.itek.de/beratung/open-masterdata
 - https://itek-branchenwissen.atlassian.net/wiki/spaces/DS/pages/535593021/Open+Masterdata

# Lieferanten mit Open Masterdata-Unterstützung

| Lieferant | ClientIDRequired | GrantType | DataPackageSendMode | UsernameRequired | CustomerNumberRequired | ClientSecretRequired |
|----------|----------|----------|----------|----------|----------|----------|
| MAINMETALL Grosshandelsgesellschaft m.b.H. | ja | password | pipedelimited | ja | nein | nein |
| GC-Gruppe GC ONLINE PLUS | ja | client_credentials | pipedelimited | ja | nein | ja |
| WIEDEMANN GmbH & Co. KG | ja | password | pipedelimited | ja | nein | nein |
| HSH Rose GmbH | ja | password | pipedelimited | ja | nein | ja |
| Mosecker Osnabrueck | ja | password | pipedelimited | ja | nein | ja |
| Buderus Deutschland | ja | password | pipedelimited | ja | nein | ja |
| FEGA & Schmitt Elektrogroßhandel GmbH | ja | password | pipedelimited | ja | ja | ja |
| Pietsch Haustechnik GmbH | ja | password | pipedelimited | ja | nein | nein |
| Sanitär-Heinze GmbH & Co. KG | ja | password | pipedelimited | ja | nein | nein |
| Friedrich Lange GmbH | ja | password | pipedelimited | ja | ja | ja |
| Sonepar | ja | password | exploded | ja | ja | nein |
| Richter+Frenzel | ja | password | pipedelimited | ja | nein | ja |
| Reisser AG| ja | password | pipedelimited | ja | ja | nein |

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
