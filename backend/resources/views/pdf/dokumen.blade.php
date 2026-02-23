<!DOCTYPE html>
<html>

<head>
    <title>Laporan Dokumen Masuk</title>
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
        <h2>Laporan Dokumen Masuk</h2>
        <p>Generated: {{ now()->format('d M Y H:i') }}</p>
    </div>

    @if(!empty($date))
        <div class="meta">
            <strong>Tanggal:</strong> {{ \Carbon\Carbon::parse($date)->format('d/m/Y') }}
        </div>
    @endif

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Tanggal</th>
                <th>Hari</th>
                <th>Waktu</th>
                <th>Asal</th>
                <th>Nama Barang</th>
                <th>Qty</th>
                <th>Pemilik</th>
                <th>Penerima</th>
            </tr>
        </thead>
        <tbody>
            @forelse($data as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($item->date)->format('d/m/Y') }}</td>
                    <td>{{ $item->day }}</td>
                    <td>{{ $item->time }}</td>
                    <td>{{ $item->origin }}</td>
                    <td>{{ $item->item_name }}</td>
                    <td>{{ $item->qty }}</td>
                    <td>{{ $item->owner }}</td>
                    <td>{{ $item->receiver }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="9" style="text-align:center">Tidak ada data dokumen</td>
                </tr>
            @endforelse
        </tbody>
    </table>
</body>

</html>

