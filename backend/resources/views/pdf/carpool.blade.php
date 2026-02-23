<!DOCTYPE html>
<html>

<head>
    <title>Laporan Carpool</title>
    <style>
        body {
            font-family: sans-serif;
            font-size: 9pt;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
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
            margin-bottom: 20px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h2>Laporan Log Carpool</h2>
        <p>Generated: {{ now()->format('d M Y H:i') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Tanggal</th>
                <th>User</th>
                <th>Kendaraan</th>
                <th>Driver</th>
                <th>Tujuan</th>
                <th>Keluar</th>
                <th>Masuk</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach($data as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($item->date)->format('d/m/Y') }}</td>
                    <td>{{ $item->user_name }}</td>
                    <td>{{ $item->vehicle ? $item->vehicle->plate : '-' }}</td>
                    <td>{{ $item->driver ? $item->driver->name : '-' }}</td>
                    <td>{{ $item->destination }}</td>
                    <td>{{ $item->trip_started_at ? \Carbon\Carbon::parse($item->trip_started_at)->format('H:i') : '-' }}
                    </td>
                    <td>{{ $item->key_returned_at ? \Carbon\Carbon::parse($item->key_returned_at)->format('H:i') : '-' }}
                    </td>
                    <td>{{ $item->status }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>

</html>