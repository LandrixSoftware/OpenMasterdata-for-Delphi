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
 - JSON-`null` wird als leerer Wert behandelt und nicht als Text `null` übernommen.
 - GTIN-Werte mit führender Null werden verlustfrei gelesen, obwohl sie formal kein gültiges JSON sind.
 - Achtstellige Datumsangaben werden sowohl als `YYYYMMDD` als auch als `DDMMYYYY` erkannt.
 - Preisstaffeln bleiben vollständig erhalten: `listPrice`, `netPrice` und `rrp` führen weiterhin die erste Stufe, alle Stufen stehen zusätzlich in `listPriceScale`, `netPriceScale` und `rrpScale`.
 - Fallback von `weight` auf die Spec-Schreibweise `weigth` in `logistics`, analog zum bereits vorhandenen `heigth`.
 - Unterstützung von `additional.attributes` im Plural, wie ihn einzelne Lieferanten senden.
 - `Document.language` und `LinePrice.descriptiion` aus der Spec 9.0.0.
 - Der optionale Query-Parameter `customerId` lässt sich über `SetCustomerId` setzen.
 - Die Sonderstatus `950` und `951` liefern laut Spezifikation ein vollständiges Produkt, nämlich den Alternativ- bzw. Nachfolgeartikel. Deren Antwort wird geparst; der Statuscode bleibt über `GetLastErrorCode` abfragbar.

## Wiederholung bei Überlast

Antworten mit `429`, `502`, `503` oder `504` werden standardmäßig zweimal wiederholt, mit 1 und 2 Sekunden Abstand. Alle übrigen Statuscodes werden nicht wiederholt, weil sie beim zweiten Versuch dieselbe Antwort ergäben.

Nennt der Server im Header `Retry-After` eine Wartezeit in Sekunden, hat diese Vorrang. Liegt sie über der zugestandenen Obergrenze von 10 Sekunden, wird **nicht** gewartet, sondern der Fehler gemeldet. Hintergrund: der Aufruf blockiert, und eine Anwendung, die eine Minute lang nicht reagiert, wirkt abgestürzt. Der Aufrufer kann anhand von `GetLastErrorCode` selbst entscheiden, ob und wann er es erneut versucht.

Beides lässt sich anpassen, etwa für Hintergrunddienste ohne Oberfläche:

```pascal
client.SetRetryPolicy(3,60); //drei Wiederholungen, bis zu 60 Sekunden Wartezeit
client.SetRetryPolicy(0,0);  //Wiederholungen abschalten
```

Bei Sammelabrufen ist zu beachten, dass sich die Wartezeiten über alle Artikel summieren.

## Felder ab OpenMasterdata 11

Die folgenden Felder sind noch nicht Teil der umgesetzten Version 9.0.2. Sie werden bereits gelesen, damit nichts verlorengeht, sobald ein Echtsystem sie liefert. In Antworten nach 9.0.2 bleiben sie leer.

 - `status` je Artikel (`200`, `404`, `950`, `951`, `952`, `960`), als Zahl in `TOpenMasterdataAPI_Result.status`. `0` bedeutet, dass die Antwort kein Statusfeld enthält.
 - `prices.promotionalPrice` als Liste von Aktionspreisen mit `startOfValidity` und `endOfValidity`.
 - `lowerBound` an Preisen, die untere Staffelgrenze. In OM 11 ist `netPrice` eine Staffel aus `BulkPrice`; die Werte stehen in `netPriceScale`.
 - `basic.noOrderBefore`, `basic.noDeliveryBefore`, `basic.noMarketingBefore`.
 - `basic.sparepartsystemURL` und `basic.sparepartsystemdescription`.
 - `additional.accessorieGroupIdManufacturer` und `additional.accessorieGroupDescrManufacturer`.

Da die Bibliothek künftig gegen reale Antworten statt gegen die Dokumentation abgeglichen wird, sollten neue Beispiel-Responses immer über die Tests geprüft werden.

## Tests

Unter `Tests` liegt ein Konsolenprogramm mit Regressionstests für den Parser und die HTML-Ausgabe.

```
Tests\run-tests.bat
```

Das Skript sucht eine installierte Delphi-Version, kompiliert die Tests und führt sie aus. Der Rückgabewert ist 0, wenn alle Tests bestanden wurden. Liegt der Ordner `Testresponses` vor, wird zusätzlich jede dort abgelegte Lieferanten-Antwort als Smoketest geparst.

Neue Beispiel-Responses lassen sich damit direkt gegen die vorhandene Parserlogik prüfen.

## Verbindung aufbauen

Eine Verbindung lässt sich auf drei Wegen anlegen. Am kürzesten direkt aus einem Abschnitt einer Ini-Datei:

```pascal
client := TOpenMasterdataApiClient.NewOpenMasterdataConnection('Mainmetall',
            Configuration,'MAINMETALL Grosshandelsgesellschaft m.b.H.');
```

Damit liest die Bibliothek Zugangsdaten, Adressen, Datenpaketauswahl und Wiederholungsstrategie selbst — einschließlich der Regel, dass die Kundennummer nur bei `CustomernumberRequired=True` in die Anmeldung geht. Zuvor legte jede Anwendung die Schlüssel selbst aus, was leicht auseinanderläuft.

Wer die Werte anderswoher bezieht, füllt den Record selbst:

```pascal
var configuration := TOpenMasterdataConfiguration.Defaults;
configuration.Username := '…';
configuration.Password := '…';
configuration.ClientID := '…';
configuration.OAuthURL := '…';
configuration.BySupplierPIDURL := '…';
configuration.DataPackages := [omd_datapackage_basic,omd_datapackage_prices];

client := TOpenMasterdataApiClient.NewOpenMasterdataConnection('Name',configuration);
```

Die bisherige Überladung mit den einzelnen Parametern bleibt unverändert bestehen.

## Abruf und Ergebnis

Neben den `Get…`-Funktionen mit `out`-Parameter gibt es `Fetch…`, das Ergebnis, Status und Meldung in einem Wert liefert:

```pascal
var response := client.FetchBySupplierPid('BOGPRP90II15');
try
  if not response.Success then
    ZeigeFehler(response.ErrorMessage)
  else
  begin
    //Der Abruf kann gelingen und trotzdem einen anderen Artikel liefern
    if response.StatusHint <> '' then
      ZeigeHinweis(response.StatusHint);
    Verarbeite(response.Product);
  end;
finally
  response.Product.Free;
end;
```

Ohne Angabe der Datenpakete gilt die Auswahl aus der Konfiguration. `response.Product` gehört dem Aufrufer.

Zu den Statuswerten 950 und 951 liefert der Server ein vollständiges Produkt — aber nicht das angefragte, sondern einen Alternativ- oder Nachfolgeartikel. Das ließ sich bisher nur über `GetLastErrorCode` erkennen. Jetzt trägt die Bibliothek den Status in das Ergebnis ein, sofern die Antwort selbst keinen führt, und `TOpenMasterdataAPI_Result` beantwortet die Frage direkt:

```pascal
if result.IsAlternativeProduct then …
if result.IsSuccessorProduct then …
if result.IsInactiveProduct then …
if result.IsRequestedProduct then …   //genau der angefragte Artikel
```

## Katalogantworten mit mehreren Produkten

Das Schema „Open Masterdata asynchron" (OM 11) liefert ein Array von Produkten statt eines einzelnen Objekts. `TOpenMasterdataAPI_ResultList` liest beides:

```pascal
var liste := TOpenMasterdataAPI_ResultList.Create(true);
try
  if liste.TryLoadFromJson(inhalt,fehler) then
    for var produkt in liste do
      Verarbeite(produkt);
finally
  liste.Free;
end;
```

Ein unbrauchbarer Eintrag verwirft nicht die ganze Liste; er wird übergangen und im Fehlertext genannt. Die Endpunkte dafür bieten die Lieferanten derzeit noch nicht an — der Parser steht bereit, sobald sie es tun.

## Zugänge prüfen

Die Tests unter `Tests` arbeiten ohne Netzwerk. Ob die hinterlegten Zugänge noch gelten, prüft ein zweites Konsolenprogramm:

```
Samples\LoginTest\run-logintest.bat
```

Es liest `Samples\configuration.ini`, meldet sich bei jedem darin konfigurierten Lieferanten an und ruft eine Artikelnummer aus `ArtNoAsCommatext` ab. Ausgegeben werden nur der Endpunkt, das Ergebnis und im Fehlerfall die Antwort des Servers — nicht die Zugangsdaten und nicht die OAuth-Antwort, die Zugriffs- und Refresh-Token im Klartext enthält.

```
run-logintest.bat Sonepar        nur Zugänge, deren Name das enthält
run-logintest.bat Sonepar cc     zusätzlich den Grant-Type übersteuern
```

Der zweite Parameter (`pw` oder `cc`) hilft bei der Eingrenzung, wenn ein Endpunkt den konfigurierten Grant-Type ablehnt. Der Rückgabewert ist 0, wenn sich alle geprüften Zugänge anmelden konnten und einen Artikel geliefert haben.

Abgefragt werden die für den Lieferanten konfigurierten Datenpakete in einem Aufruf; die Antwort wird eingelesen und es wird gemeldet, welche Bereiche tatsächlich gefüllt sind. Scheitert dieser Abruf, sucht das Programm die Ursache: es wiederholt zuerst denselben Aufruf unverändert — gelingt er dann, war die Störung vorübergehend —, probiert danach den jeweils anderen `DataPackageSendMode` und schließlich jedes Datenpaket einzeln. Damit lässt sich unterscheiden, ob ein Lieferant die Paketliste anders erwartet oder ob er ein bestimmtes Datenpaket nicht ausliefern kann.

Welche Datenpakete abgefragt werden, steuert der optionale Schlüssel `DataPackages` je Lieferant, etwa `DataPackages=basic,descriptions,logistics,pictures,documents`. Als Trenner gelten Komma, Semikolon, senkrechter Strich, Leerzeichen, Tabulator und Zeilenumbruch. Das hilft bei Lieferanten, die ein einzelnes Paket nicht ausliefern können und die gesamte Abfrage daran scheitern lassen.

Fehlt der Schlüssel, ist er leer oder nennt er kein einziges bekanntes Paket, werden alle Pakete angefragt — eine leere Auswahl würde jede Abfrage scheitern lassen. Nicht erkannte Namen werden übergangen und zusätzlich gemeldet, damit ein Tippfehler nicht unbemerkt bleibt.

Als Vorlage für die Konfiguration dient `Samples\configuration.sample.ini`. Die echte `configuration.ini` enthält Zugangsdaten und ist von der Versionsverwaltung ausgenommen.

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

Die Tabelle hält fest, was die Lieferanten in der Praxis erwarten. Die Spaltennamen entsprechen den Schlüsseln in `configuration.ini`, ausgewertet wird davon derzeit allein `CustomernumberRequired`; `ClientIDRequired`, `UsernameRequired` und `ClientSecretRequired` sind Notizen für die Einrichtung und werden vom Code nicht gelesen.

`CustomernumberRequired` entscheidet, ob die Kundennummer Teil der Anmeldung ist. Verlangt ein Lieferant sie, wird sie mit einem Tabulator getrennt an den Benutzernamen gehängt; ist kein Benutzername gesetzt, geht sie allein als `username` hinaus. Verlangt er sie nicht, muss sie beim Login außen vor bleiben, sonst weist der Server die Zugangsdaten zurück. Fehlt der Schlüssel, wird eine eingetragene Kundennummer gesendet.

In der Konfiguration sind `True`/`False` die üblichen Werte; `ja`/`nein` werden ebenfalls verstanden.

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
| Viessmann| ja | password | pipedelimited | ja | Nein | Ja |

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

## Hinweise zur Aktualisierung bestehender Anwendungen

Zwei Änderungen können bestehenden Code betreffen:

 - Die Objekt- und Listen-Properties der Datentypen sind schreibgeschützt (`read` statt `read/write`), etwa `prices.listPrice`, `logistics.measureA` oder `additional.attribute`. Eine Zuweisung von außen hätte die im Konstruktor erzeugte Instanz lecken lassen. Die Objekte selbst sind unverändert veränderbar, nur das Ersetzen der Instanz entfällt.
 - Die Aufzählungstypen `TOpenMasterdataAPI_CarryingCategory`, `TOpenMasterdataAPI_PackageType` und `TOpenMasterdataAPI_RawMaterial` haben neue Werte erhalten. Dadurch verschieben sich die Ordinalwerte der bestehenden Einträge. Wer diese Werte als Zahl gespeichert hat, muss die Daten umsetzen. `omdCarryingCategory_None` steht neu an erster Stelle, weil `omdCarryingCategory_0` eine gültige Beförderungskategorie ist und nicht „nicht angegeben" bedeutet.

Geändertes Verhalten bei gleicher Signatur:

 - `LoadFromJson` und `TryLoadFromJson` leeren das Ergebnisobjekt vor jedem Ladevorgang. Ein wiederverwendetes Objekt behält damit keine Werte des zuvor geladenen Artikels mehr.
 - `NewOpenMasterdataConnection` übernimmt bei bereits bekanntem Verbindungsnamen die übergebenen Zugangsdaten. Weichen sie ab, wird der bisherige Token verworfen.
 - `GetLastErrorCode` liefert nach einem erfolgreichen Abruf 0. Bei den Sonderstatus 950 und 951 bleibt der Statuscode erhalten, obwohl der Abruf als erfolgreich gilt.
 - `AsHtml` reicht Lieferanten-HTML nicht mehr unverändert durch. Nicht freigegebene Tags und sämtliche Attribute werden entfernt, Adressen nur mit den Schemata `http`, `https` und `mailto` verlinkt.
 - Fehlgeschlagene Bild- und Dokumentdownloads werden nicht mehr zwischengespeichert, sondern beim nächsten Zugriff erneut versucht.
