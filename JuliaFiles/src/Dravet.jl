#find dravet UUIDs

reports = useReports();
icds = useICD();

dravet = searchByICD("dravet");
dravet = unique(dravet,:recording)

