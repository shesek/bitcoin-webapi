express = require 'express'
{ bitcoin_jsonrpc, iferr, out_paid_to, format_unspent } = require './util'

bitcoin = bitcoin_jsonrpc process.env.BITCOIN_URL or throw new Error 'Missing BITCOIN_URL'

express().configure ->
  @set 'port', process.env.PORT or 9999
  @set 'host', process.env.HOST or '127.0.0.1'

  @use express.favicon()
  @use express.logger 'dev'
  @use express.urlencoded()

  if process.env.CORS then @use (req, res, next) ->
    res.set 'Access-Control-Allow-Origin', '*'
    do next

  @get '/unspent/:address', (req, res, next) ->
    address = req.params.address.replace /\W+/g, ''
    bitcoin.cmd 'searchrawtransactions', address, iferr next, (txs) ->
      unspent = {}
      for tx in txs
        # Delete spent inputs
        delete unspent["#{txid}:#{vout}"] for { txid, vout } in tx.vin
        
        # Add new unspent
        for vout in tx.vout when out_paid_to vout, address
          unspent["#{tx.txid}:#{vout.n}"] = { tx, vout }
      res.json (format_unspent input for _, input of unspent)

  @post '/pushtx', (req, res, next) ->
    rawtx = req.body.tx.replace /[^0-9a-f]/g, ''
    bitcoin.cmd 'sendrawtransaction', rawtx, iferr next, ->
      res.send 200

  if @settings.env is 'development'
    @use express.errorHandler()
  else
    @use (err, req, res, next) ->
      res.send 500, err?.message or err or "Unknown error"

  @listen @settings.port, @settings.host, => console.log "Listening on #{@settings.host}:#{@settings.port}"
