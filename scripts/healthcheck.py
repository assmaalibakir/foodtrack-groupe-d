# On importe la bibliotheque requests
# Elle permet d'envoyer des requetes HTTP
import requests

# On importe time
# Il permet de mesurer le temps de reponse
import time

# On importe sys
# Il permet de recuperer les arguments et de gerer les codes de sortie
import sys


# Verifie qu'une URL a bien ete fournie au lancement du script
if len(sys.argv) < 2:

    # Affiche la bonne facon de lancer le script
    print("Usage : python healthcheck.py <URL>")

    # Code 1 = erreur
    sys.exit(1)


# Recupere l'URL donnee dans la commande
# Exemple :
# python healthcheck.py http://localhost:8080/api/
url = sys.argv[1]


# Affiche l'URL qui va etre testee
print(f"URL testee : {url}")


# Enregistre l'heure de depart
# Cela permettra de calculer la latence
start = time.time()


try:
    # Envoie une requete HTTP GET vers l'URL
    # timeout=5 signifie que le script attend maximum 5 secondes
    response = requests.get(url, timeout=5)


    # Calcule le temps de reponse
    latency = time.time() - start


    # Affiche le code HTTP retourne par le serveur
    print(f"Code HTTP : {response.status_code}")


    # Affiche la latence avec 3 chiffres apres la virgule
    print(f"Latence : {latency:.3f} secondes")


    # Verifie si le serveur a retourne un code HTTP 200
    if response.status_code == 200:

        # Le service est considere comme disponible
        print("Statut : OK")

        # Code 0 = succes
        # Ce code pourra etre utilise par une pipeline ou un CronJob
        sys.exit(0)

    else:
        # Si le code HTTP est different de 200
        # le service est considere comme ayant un probleme
        print("Statut : ERREUR")

        # Code 1 = erreur
        sys.exit(1)


# Cette partie est executee si la requete HTTP echoue completement
# Exemple :
# - serveur inaccessible
# - URL incorrecte
# - probleme reseau
# - timeout
except requests.RequestException as e:

    # Affiche le detail de l'erreur
    print(f"Erreur : {e}")

    # Code 1 = erreur
    sys.exit(1)