<!DOCTYPE html>
<html>

<head>
    <title>Laporan Audit KM</title>
    <style>
        body {
            font-family: sans-serif;
            font-size: 9pt;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 14px;
        }

        th,
        td {
            border: 1px solid #333;
            padding: 4px;
            text-align: left;
        }

        th {
            background-color: #f2f2f2;
        }

        .header {
            text-align: center;
            margin-bottom: 16px;
        }

        .meta {
            margin-top: 6px;
            margin-bottom: 6px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h2>Laporan Audit KM</h2>
        <p>Generated: {{ now()->format('d M Y H:i') }}</p>
    </div>

    @if(!empty($date))
        <div class="meta">
            <strong>Tanggal Audit:</strong> {{ \Carbon\Carbon::parse($date)->format('d/m/Y') }}
        </div>
    @endif

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Tanggal</th>
                <th>Kendaraan</th>
                <th>Oleh</th>
                <th>System KM</th>
                <th>Aktual KM</th>
                <th>Selisih</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse($data as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($item->date)->format('d/m/Y') }}</td>
                    <td>{{ $item->vehicle ? $item->vehicle->plate : '-' }}</td>
                    <td>{{ $item->user ? $item->user->name : '-' }}</td>
                    <td>{{ $item->recorded_km }}</td>
                    <td>{{ $item->actual_km }}</td>
                    <td>{{ $item->difference }}</td>
                    <td>{{ $item->is_alert ? 'Alert' : 'OK' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="8" style="text-align:center">Tidak ada data audit</td>
                </tr>
            @endforelse
        </tbody>
    </table>
</body>

</html>

