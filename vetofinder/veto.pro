pro veto, veto_msg
  openw,lun, 'veto.out',/append,/GET_LUN
  printf,lun, veto_msg
  free_lun,lun
return
end
