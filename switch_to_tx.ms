for m in (getclassinstances vrayHDRI) do m.hdriMapName = getFilenamePath m.hdriMapName + getFilenameFile m.hdriMapName + ".tx"
