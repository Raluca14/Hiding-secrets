# Hiding-secrets
Implementați în Verilog un circuit secvențial sincron care ascunde un mesaj secret într-o imagine


Precizari initiale:
Implementarea cerinteie si a automatului pentru rezolvarea acesteia este in fisierul process.v
Automatul implementat pentru aceasta tema are 31 de stari, pe care le voi explica succinct mai jos. Numarul de stari este ridicat deoarece nu am refolosit stari anterioare in dezvoltarea takurilor, astfel ca o parte din ele sunt copiate si replasate in alta parte de cod. 
Variabila done  este o solutie pe care eu am folosit-o pentru a impiedica formarea de bucle infinite sau implementarea de mai multe ori, in mod eronat, a unei instuctiuni ( de exemplu a unui if, in care se incrementeaza un semnal). Cu o stare precedenta folosorii lui, done primeste valoarea 1, valoare ce este ulterior schimbata in 0 in starea urmatoare, ca urmare a efectuarii unei anumite instructiuni. done==1 este o conditie care se intalneste in multe constructii if de-a lungul implementarii.
Variabile folosite pentru fiecare task sunt explicate prim comentarii in zona de  inceput a modulului.
Starea 31 a fost adaugata ulterior ca parte a rezolvarii cazului in care toate valorii unei submatrices sunt egale (task3).

0: Starea de start a automatului si totodata a Task1, singurele semnale initializate aici sunt max,min si done.  Automatul auxliliar (afferent task1) se va intoarce aici din starea 3 pentru a incepe modificarea in grayscale a unui alt pixel. Restul automatului auxiliar pentru acest task descrie transformarea unui singur pixel in grayscale.

1:  Calcularea min si max pentru pixelul current are loc in aceasta stare. S-a ales operatorul ternar pentru a evita o secventa de if-uri. Valoarea pixelului curent este retinuta in in_pix, valoare ce se schimba odata cu schimbarea semnalelor row si col.

2: In aceasta stare out_pix_c este modificat, pe R si B sunt puse 8 zerouri, iar pe G va fi inregistrata valoarea in gray scale ceruta. Valoarea out_pix_c este inregistratat automat pe out_pix ( prin folosirea assign la finalul automatului/blocului always) si, implicit, se va inregistra automat si in imaginea initiala.	 

3: starea in care se trece la urmatorul pixel din imagine, in functie de unde este localizat pixelul precedent convertit. Se verifica de asemenea daca imaginea a fost complet transformata, caz in care se trece mai departe la implementarea task2. Pentru ca pixelil nu pot fi cititi decat cate unul per semnal de ceas, automatul se va intoarce in starea 0 pentru a preluacra alt pixel, in cazul in care nu s-a a ajuns la finalul imaginii (pozitia 63x63)

4: Marcheaza sfarsitul task-ului 1, prin aseratarea semnalului g_done(implicit grey_done) cu 1, cat si inceputul task2. Se reincepe de la inceputul imaginii (pozitia 0x0), dar pentru care r=0,c=0, iar cum pentru acest task se lucreaza pe matrici de 4x4 pixeli, apar si variabilele r_m, c_m.

5: O stare in care se citeste un singur pixel, pentru o singura poztie din matricea matrix, pozitie indicata prin r_m si c_m

6:  Aceasta stare decide daca fiecare pozitie din matrix a fost ocupata de pixeli si se poate continua executarea task-ului sau row si col sunt incrementate pentru a se citi in continuare pixeli in matricea matrix.
7: Cum pixelii au fost cititi in matrix, nu mai este nevoie de citire si prelucrare individuala a pixelilor, acum se poate lucre direct pe inregistrarile din matrix, folosindu-se bucle for. In aceasta stare este calculate AVG.

8:  Deviatia var este calculate in aceasta stare, folosindu-se o noua variabila sum2, pentru a nu altera negative construirea AVG in starea precedenta. Se initializeaza counter=0 pentru a putea numara cati de 1 apar in matrix in starea urmatoare.

9: Conform algoritmului de compresie, se mapeaza matrix cu 0 si 1, se numara de asemnea si cati de 1 apar

10: Starea in case se calculeaza Lm si Hm, folosind datele din starile anterioare.

11: Matricea se reface conforma algoritmului de compresie, cee ace conduce la finalizarea modificarilor pentru matricea curenta.

16: Acum matrix trebuie suprascrisa peste imagine/data la ieri. Acest lucru se face, din nou, pixel cu pixel. Starea 16, adaugata de asemenea anterior pregateste aceasta scrie.

12:  Un singur pixel din matrix este dat spre iesire, in aceasta stare se va reveni pentru fiecare pixel, pana cand se ajunge la pozitia 3x3 din matrix.

13: In aceasta stare se decide daca scrie unei matrice de 4x4 s-a incheiat, caz in care se continua spre urmatoare matrice din imagine, sau  mai sunt elemente din matrix nescrise, caz in care automatul se reintoarce in starea 12, dupa ce r_m si c_m sunt incrementate.

14: Starea 14 identifica care este urmatoarea matrice care trebuie citita in matrix si prelucrata de automat sau daca s-a ajuns la ultima matrice din imagine si automatul continua spre task3.

15: Starea de final a task2, toata imaginea a fost prelucrata. Pe matrix este ultima matrice din blocul de 64x64 din colt dreapta jos.

17: Starea de start a task 3. Se initializeaza mai multe semnala care sunt necesare in acest task, de asemenea se reseteaza r_m si c_m in pregatirea citirii unei noi matrici de 4x4. Pentru acest task am folosit  o noua matrice, matrix2, desi as fi putut folosi chair matrix, folosita la task precedent. 

Starile 18 si 19 sunt identice cu starile 5 si 6 din task 2.

20: Pentru ca ar fi fost dificil sa retinem Lm si Hm pentru fiecare dintre matricele identificate la punctul anterior, aceste 2 semnale trebuiesc din nou identificate. Stim insa ca matrix 2 are in componenta sa maxim 2 valori. In aceasta stare se identifica acele 2 valori, desi initial amandoua sunt initializare in starea 19 cu matrix2[0][0] (pentru a ne asigura ca amandoua au in efectuarea automatului o valoare prezenta in matrix2

21: Dupa identificarea valorilor se decide care este Lm si Hm si eventual se interschimba intre ele.

22:  In aceasta stare se trimit valori pentru modulul base2_to_base3 pentru a fi prelucrat sirul auxiliar base3_aux care va fi folosit la starile viitoare
	
23: se citeste valoarea de la iesirea modulului base3_to_base2 doar cand semnalul ok este 1.

24: In acesta stare se identifica pozitiile din matrix2 in care se gasesc pentru prima data Lm si Hm. 

31: Pentru cazul in care toate elementele din matrix2 sunt egale, Lm va fi identificat pe pozitia 0x0 si Hm pe pozitia 0x1; Faptul ca sunt egale este reprezentat prin faptul ca, dupa ce initial Lm=Hm=matrix2[0][0] nu a mai fost gasit un alt element diferit, deci Lm=Hm

25: In acesta stare este codificat mesajul din base2_aux pentru fiecare dintre elementele matrix2, mai putin cele de pe cele 2 pozitii identificare ca Hm si Lm. 
26: In acest punct matrix2 a fost complet modificata si se pregateste scrierea pe imaginere/la iesire
Starile 27,28 si 14 sunt identice cu 12,13,14. Citirea si scrirea pentru matrix si matrix2 se fac identic pentru task2 si task3.
30: Starea de final a automatului in care se aserteaza si encode_done cu 1.


