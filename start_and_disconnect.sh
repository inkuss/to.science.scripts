#!/bin/bash
# Vorgeschaltetes Skript für Aufruf aus java.lang.ProcessBuilder um "nohup" zum implementieren
# Autor: I. Kuss, 03.07.2026
# Quelle: https://stackoverflow.com/questions/52394419/creating-a-nohup-process-in-java

nohup "$@" & 
