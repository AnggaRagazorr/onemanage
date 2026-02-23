<!DOCTYPE html>
<html>

<head>
    <title>Laporan Rekap Harian</title>
    <style>
        body {
            font-family: sans-serif;
            font-size: 10pt;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        th,
        td {
            border: 1px solid #333;
            padding: 6px;
            text-align: left;
        }

        th {
            background-color: #f2f2f2;
        }

        .header {
            text-align: center;
            margin-bottom: 20px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h2>Laporan Rekap Harian Security</h2>
        <p>Generated: {{ now()->format('d M Y H:i') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Tanggal</th>
                <th>Shift</th>
                <th>Waktu</th>
                <th>Guard</th>
                <th>Aktivitas</th>
            </tr>
        </thead>
        <tbody>
            @foreach($data as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($item->date)->format('d/m/Y') }}</td>
                    <td>{{ strtoupper($item->shift) }}</td>
                    <td>{{ $item->start_time }} - {{ $item->end_time }}</td>
                    <td>{{ $item->guard }}</td>
                    <td>{{ $item->activity }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>

</html>